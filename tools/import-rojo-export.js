const fs = require("fs");
const path = require("path");

const repoRoot = path.resolve(__dirname, "..");
const inputPath = path.join(repoRoot, "exports", "rojo_export.json");
const srcRoot = path.join(repoRoot, "src");

const scriptSuffixByClass = {
	Script: ".server.lua",
	LocalScript: ".client.lua",
	ModuleScript: ".lua",
};

const knownRoots = new Set([
	"ReplicatedFirst",
	"ReplicatedStorage",
	"ServerScriptService",
	"ServerStorage",
	"StarterGui",
	"StarterPack",
	"StarterPlayer",
	"Workspace",
	"Lighting",
]);

function sanitizePart(value) {
	return String(value)
		.replace(/[<>:"/\\|?*\x00-\x1f]/g, "_")
		.replace(/\s+$/g, "")
		.replace(/^\.+$/g, "_")
		|| "_";
}

function stripRojoContainer(parts, containerName) {
	if (parts[0] === containerName) {
		return parts.slice(1);
	}

	return parts;
}

function mapToRojoPath(record) {
	let parts = Array.isArray(record.path) ? record.path.slice() : [];

	if (parts[0] === "game") {
		parts = parts.slice(1);
	}

	const service = parts[0];
	let rest = parts.slice(1);

	switch (service) {
		case "ReplicatedStorage":
			return path.join(srcRoot, "ReplicatedStorage", ...rest);

		case "ServerScriptService":
			return path.join(srcRoot, "ServerScriptService", ...rest);

		case "StarterPlayer":
			return path.join(srcRoot, "StarterPlayer", ...rest);

		default:
			if (knownRoots.has(service)) {
				return path.join(srcRoot, service, ...rest);
			}

			return path.join(srcRoot, "_unmapped", ...parts);
	}
}

function addScriptSuffix(filePath, className) {
	const suffix = scriptSuffixByClass[className] || ".lua";
	const directory = path.dirname(filePath);
	const baseName = sanitizePart(path.basename(filePath));
	return path.join(directory, `${baseName}${suffix}`);
}

function uniquePath(filePath) {
	if (!fs.existsSync(filePath)) {
		return filePath;
	}

	const parsed = path.parse(filePath);

	for (let index = 2; index < 10000; index += 1) {
		const candidate = path.join(parsed.dir, `${parsed.name}_${index}${parsed.ext}`);

		if (!fs.existsSync(candidate)) {
			return candidate;
		}
	}

	throw new Error(`Could not find a unique path for ${filePath}`);
}

function main() {
	if (!fs.existsSync(inputPath)) {
		console.error(`Missing export file: ${inputPath}`);
		console.error("Create exports/rojo_export.json from ServerStorage.__RojoExportJson first.");
		process.exit(1);
	}

	const payload = JSON.parse(fs.readFileSync(inputPath, "utf8"));
	const scripts = Array.isArray(payload.scripts) ? payload.scripts : payload;

	if (!Array.isArray(scripts)) {
		throw new Error("Expected JSON with a scripts array, or a raw array of scripts.");
	}

	const written = [];

	for (const record of scripts) {
		const targetWithoutSuffix = mapToRojoPath(record)
			.split(path.sep)
			.map((part, index) => index < 2 ? part : sanitizePart(part))
			.join(path.sep);
		const targetPath = uniquePath(addScriptSuffix(targetWithoutSuffix, record.className));

		fs.mkdirSync(path.dirname(targetPath), { recursive: true });
		fs.writeFileSync(targetPath, record.source || "", "utf8");
		written.push(path.relative(repoRoot, targetPath));
	}

	console.log(`Imported ${written.length} scripts:`);
	for (const file of written) {
		console.log(`- ${file}`);
	}
}

main();

const {readdirSync} = require("node:fs");
const {join, resolve} = require("node:path");
const {execFileSync} = require("node:child_process");

const root = resolve(__dirname, "..");
function check(path) {
  for (const entry of readdirSync(path, {withFileTypes: true})) {
    const file = join(path, entry.name);
    if (entry.isDirectory()) check(file);
    else if (file.endsWith(".js")) execFileSync(process.execPath, ["--check", file], {stdio: "inherit"});
  }
}
execFileSync(process.execPath, ["--check", join(root, "index.js")], {stdio: "inherit"});
for (const directory of ["src", "scripts", "tests"]) check(join(root, directory));

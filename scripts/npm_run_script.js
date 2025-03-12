#!/usr/bin/env node

async function main() {
  const [
    { execSync, spawnSync, spawn },
    fs,
    path
  ] = await Promise.all([
    import('child_process'),
    import('fs'),
    import('path')
  ]);

  // 1. Use fd to locate all package.json files (ignoring node_modules)
  function findPackageJsonFiles() {
    try {
      const output = execSync('fd --glob package.json --type f --exclude node_modules', { encoding: 'utf-8' });
      return output.split('\n').filter(line => line.trim() !== '');
    } catch (err) {
      console.error('Error running fd:', err.message);
      process.exit(1);
    }
  }

  // 2. Asynchronously extract the scripts from a package.json file
  async function getScriptsFromFile(filePath) {
    try {
      const content = await fs.promises.readFile(filePath, 'utf-8');
      const pkg = JSON.parse(content);
      if (pkg.scripts && typeof pkg.scripts === 'object') {
        // Use the package "name" if available, otherwise the directory name
        const pkgName = pkg.name || path.basename(path.dirname(filePath));
        const scriptNames = Object.keys(pkg.scripts);
        return { pkgName, scriptNames, filePath };
      }
    } catch (err) {
      console.error(`Error reading/parsing ${filePath}:`, err.message);
    }
    return null;
  }

  const packageFiles = findPackageJsonFiles();

  // Process all package.json files concurrently
  const results = await Promise.all(packageFiles.map(file => getScriptsFromFile(file)));

  const mapping = {}; // Map display string to { dir, script }
  const options = [];

  for (const result of results) {
    if (result && result.scriptNames.length > 0) {
      for (const script of result.scriptNames) {
        // Format: "<PKG_NAME>: <SCRIPT_NAME>"
        const display = `${result.pkgName}: ${script}`;
        mapping[display] = { dir: path.dirname(result.filePath), script };
        options.push(display);
      }
    }
  }

  if (options.length === 0) {
    console.error('No package scripts found.');
    process.exit(1);
  }

  // 3. Pass the options to fzf for interactive selection
  const fzfInput = options.join('\n');
  const fzfResult = spawnSync('fzf', { input: fzfInput, encoding: 'utf-8' });
  if (fzfResult.error) {
    console.error('Error running fzf:', fzfResult.error.message);
    process.exit(1);
  }

  const selected = fzfResult.stdout.trim();
  if (!selected) {
    console.error('No selection made.');
    process.exit(1);
  }

  const selectedEntry = mapping[selected];
  if (!selectedEntry) {
    console.error('Selected option not recognized.');
    process.exit(1);
  }

  // 4. Run the selected script using npm run from its package directory
  console.log(`\nRunning script "${selectedEntry.script}" in directory "${selectedEntry.dir}"...\n`);
  const npmProc = spawn('npm', ['run', selectedEntry.script], {
    cwd: selectedEntry.dir,
    stdio: 'inherit'
  });

  npmProc.on('close', (code) => {
    process.exit(code);
  });
}

main()

#! /usr/bin/env python3
# taken from: https://unix.stackexchange.com/a/369653/65781
from apt import cache

manual = set(pkg for pkg in cache.Cache() if pkg.is_installed and not pkg.is_auto_installed)
depends = set(dep_pkg.name for pkg in manual for dep in pkg.installed.get_dependencies('PreDepends', 'Depends', 'Recommends') for dep_pkg in dep)

print('\n'.join(pkg.name for pkg in manual if pkg.name not in depends))

#!/usr/bin/env python

import os
import ast
import sys
from typing import Set, Dict, List, Tuple

def _build_module_map(addons_dirs: List[str]) -> Dict[str, str]:
    """
    Scans multiple directories to build a mapping of all module names
    to their manifest file paths.
    """
    module_manifest_map = {}
    print("Building a map of all available modules across specified directories...")
    for addons_dir in addons_dirs:
        if not os.path.isdir(addons_dir):
            print(f"Warning: Directory '{addons_dir}' does not exist. Skipping.")
            continue
        for root, _, files in os.walk(addons_dir):
            if '__manifest__.py' in files:
                module_name = os.path.basename(root)
                manifest_path = os.path.join(root, '__manifest__.py')
                module_manifest_map[module_name] = manifest_path
    return module_manifest_map

def _find_recursive_dependencies(module_name: str, module_manifest_map: Dict[str, str], all_dependencies: Set[str], processed_modules: Set[str]):
    """
    Recursively finds all dependencies for a given Odoo module using the pre-built module map.

    Args:
        module_name (str): The name of the module to check.
        module_manifest_map (Dict[str, str]): A dictionary mapping module names to manifest paths.
        all_dependencies (Set[str]): The set to accumulate all found dependencies.
        processed_modules (Set[str]): A set of modules already processed to prevent circular dependencies.
    """
    # Avoid reprocessing the same module
    if module_name in processed_modules:
        return
    processed_modules.add(module_name)

    manifest_path = module_manifest_map.get(module_name)
    if not manifest_path:
        # We don't print a warning here, as it's common for core Odoo modules to not
        # be in the provided addons paths.
        return

    try:
        with open(manifest_path, 'r', encoding='utf-8') as f:
            manifest_content = f.read()
            manifest_dict = ast.literal_eval(manifest_content)

        if 'depends' in manifest_dict and isinstance(manifest_dict['depends'], list):
            new_dependencies = manifest_dict['depends']
            print(f"Found dependencies for '{module_name}': {new_dependencies}")
            all_dependencies.update(new_dependencies)

            # Recurse into the new dependencies
            for dep in new_dependencies:
                _find_recursive_dependencies(dep, module_manifest_map, all_dependencies, processed_modules)

    except (IOError, SyntaxError, ValueError) as e:
        print(f"Warning: Could not process manifest file for '{module_name}'. Error: {e}")

def get_all_odoo_dependencies(custom_addons_dir: str, module_manifest_map: Dict[str, str]) -> Dict[str, str]:
    """
    Scans a directory for Odoo addons and returns a dictionary of all
    their dependent modules (name to path), including sub-dependencies, using a pre-built map.

    Args:
        custom_addons_dir (str): The path to the directory containing the top-level custom addons.
        module_manifest_map (Dict[str, str]): A dictionary of all available modules.

    Returns:
        Dict[str, str]: A dictionary mapping unique module names to their full paths.
    """
    dependencies_set = set()
    processed_modules = set()
    print(f"\nScanning custom addons in: {custom_addons_dir}")

    # First, find all top-level addons and their immediate dependencies
    for root, _, files in os.walk(custom_addons_dir):
        if '__manifest__.py' in files:
            try:
                with open(os.path.join(root, '__manifest__.py'), 'r', encoding='utf-8') as f:
                    manifest_dict = ast.literal_eval(f.read())
                    if 'depends' in manifest_dict and isinstance(manifest_dict['depends'], list):
                        dependencies_set.update(manifest_dict['depends'])
                        # Recursively find dependencies for each of the top-level addons' dependencies
                        for dep in manifest_dict['depends']:
                            _find_recursive_dependencies(dep, module_manifest_map, dependencies_set, processed_modules)
            except (IOError, SyntaxError, ValueError) as e:
                print(f"Warning: Could not process manifest file at '{os.path.join(root, '__manifest__.py')}'. Error: {e}")

    # Now, build the final dictionary with paths
    final_dependencies = {}
    for dep in dependencies_set:
        path = module_manifest_map.get(dep)
        if path:
            # We store the directory path, not the manifest file path
            final_dependencies[dep] = os.path.dirname(path)
    
    return final_dependencies

def main():
    """
    Main function to run the script from the command line.
    """
    if len(sys.argv) < 3:
        print("Usage: python get_dependencies.py /path/to/custom/addons /path/to/all/addons1 /path/to/all/addons2 ...")
        sys.exit(1)

    custom_addons_dir = sys.argv[1]
    other_addons_dirs = sys.argv[2:]
    
    # Make a single list of all addon directories for mapping
    all_addons_dirs = [custom_addons_dir] + other_addons_dirs

    # Build the module map from all directories
    module_manifest_map = _build_module_map(all_addons_dirs)
    
    # Get the dependencies starting from the custom addons directory
    all_dependencies = get_all_odoo_dependencies(custom_addons_dir, module_manifest_map)

    print("-" * 50)
    if all_dependencies:
        print("Final list of all unique Odoo module dependencies (including sub-dependencies):")
        # Sort the dependencies by their full path before printing
        sorted_dependencies = sorted(all_dependencies.items(), key=lambda item: item[1])
        for dep, path in sorted_dependencies:
            print(f"- {dep} (Path: {path})")
    else:
        print("No dependencies found in the specified directories.")
    print("-" * 50)

if __name__ == "__main__":
    main()

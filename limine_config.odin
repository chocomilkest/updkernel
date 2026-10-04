package main

import "core:log"
import "core:os"
import "core:strings"

// TODO: find file names and check if they exist
// matched_files: [dynamic]string
// defer delete(matched_files)
//
// for file in boot_files {
// 	version_match, found := regex.match(version_regex, file.name)
// 	if !found {
// 		continue
// 	}
// 	defer regex.destroy(version_match)
//
// 	version := version_match.groups[0]
//
// 	if version == kernel_version {
// 		fmt.printfln("{} has {}", file.name, kernel_version)
// 		append(&matched_files, file.fullpath)
// 	} else {
// 		fmt.printfln("{} doesnt have {}", file.name, kernel_version)
// 	}
// }
update_config :: proc(
	kernel_version: string,
	// matched_files:  []string,
) -> (
	new_config: string,
	ok: bool,
) {
	config_bytes, conf_err := os.read_entire_file("/boot/limine.conf", context.allocator)
	config_string := string(config_bytes)
	config_lines := strings.split_lines(config_string)

	for line, i in config_lines {
		version, found := match_kernel_version(line)
		if !found || version == kernel_version {
			log.debug("didn't find any versions in", line)
			continue
		}

		new_line, _ := strings.replace_all(line, version, kernel_version)
		config_lines[i] = new_line
	}

	updated := strings.join(config_lines, "\n")

	if updated == config_string {
		log.warn("Config wasn't changed.")
		return "", false
	}

	return updated, true
}

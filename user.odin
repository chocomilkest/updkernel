/*
this file is dedicated to accessing /boot
by without root (through user acc)
*/

package main

import "core:log"
import "core:os"

user_boot_matching_files :: proc(
	kernel_version: string,
) -> (
	matched_files: [dynamic]string,
	ok: bool,
) {
	files, files_err := os.read_all_directory_by_path("/boot", context.allocator)
	if files_err != nil {
		log.error("failed to read /boot directory:", files_err)
		return {}, false
	}

	for file in files {
		version, matched := match_kernel_version(file.name)
		if !matched {
			continue
		}

		if version == kernel_version {
			_, append_err := append(&matched_files, file.fullpath)
			if append_err != nil {
				log.error("failed to append filepath:", append_err)
				return {}, false
			}
		}
	}

	return matched_files, true
}

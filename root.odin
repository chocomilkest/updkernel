/*
this file is dedicated to accessing /boot
by doing it with sudo/doas
*/

/*
TODO: THIS IS A TEMPORARY IMPLEMENTATION
MOVE LINKING AND READING TO ELEVATED
*/

package main

import "core:log"
import "core:os"
import "core:strings"
import "core:text/regex"

get_su_util :: proc() -> string {
	if os.exists("/bin/doas") {
		return "doas"
	} else if os.exists("/bin/sudo") {
		return "sudo"
	} else {
		log.error("couldn't find a superuser util (sudo/doas)")
		os.exit(1)
	}
}

root_boot_matching_files :: proc(
	kernel_version: string,
	version_regex: regex.Regular_Expression,
) -> (
	matched_files: [dynamic]string,
	ok: bool,
) {
	return {}, true
}

root_boot_link_files :: proc(files: []string, kernel_version: string) -> (ok: bool) {
	su_util := get_su_util()

	for filepath in files {
		kernel_version_dash, _ := strings.concatenate({kernel_version, "-"})
		no_version_path, _ := strings.replace(filepath, kernel_version_dash, "", 1)


		_, _, _, process_err := os.process_exec(
			{command = {su_util, "cp", filepath, no_version_path}},
			context.allocator,
		)
		if process_err != nil {
			log.error("failed to link file:", process_err)
			return false
		}
	}

	return true
}

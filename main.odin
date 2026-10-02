// TODO: move os.exit(1) out of functions into main

package main

import "core:flags"
import "core:log"
import "core:os"
import "core:text/match"

// TODO: figure out how odin implements short flags
Program_Options :: struct {
	verbose: bool `usage:"Verbose logging"`,
}

match_kernel_version :: proc(haystack: string) -> (matched: string, found: bool) {
	// NOTE: matches even 298018931.29838123.89023108923
	// no im not using regex its BROKEN IN ODIN
	matcher := match.matcher_init(haystack, "%d+%.%d+%.%d+")
	return match.matcher_match(&matcher)
}

main :: proc() {
	opts: Program_Options
	flags.parse_or_exit(&opts, os.args, .Odin)

	// stupid odin doesnt let me put it in an if scope........
	context.logger = log.create_console_logger(opts.verbose ? .Debug : .Info)
	log.debug(opts)

	kernel_version := get_kernel_version()
	log.debug(kernel_version)

	readable, writable := get_boot_permision()

	version_matched_files, ok := user_boot_matching_files(kernel_version)
	if !ok {
		os.exit(1)
	}
	log.debug(version_matched_files)

	if ok := root_boot_link_files(version_matched_files[:], kernel_version); !ok {
		os.exit(1)
	}
}

get_kernel_version :: proc() -> string {
	real_path, link_err := os.read_link("/usr/src/linux", context.allocator)
	if link_err != nil {
		switch link_err {
		case .Not_Exist:
			log.error("/usr/src/linux does not exist")
		case .EINVAL:
			log.error("/usr/src/linux is not a symbolic link")
		case:
			log.error("unhandled error occured:", link_err)
		}
		os.exit(1)
	}

	version_match, kernel_matched := match_kernel_version(real_path)
	if !kernel_matched {
		log.error("Failed to find kernel version in /usr/src/linux symlink")
		os.exit(1)
	}

	return version_match
}

// TODO: dont assume user running it as non-root, add a check
// for user 0
get_boot_permision :: proc() -> (readable, writable: bool) {
	boot_stats, stats_err := os.stat("/boot", context.allocator)
	if stats_err != nil {
		log.error("Failed to get /boot stats:", stats_err)
		os.exit(1)
	}

	readable = .Read_Other in boot_stats.mode
	writable = .Write_Other in boot_stats.mode

	return readable, writable
}

package main

import "core:flags"
import "core:fmt"
import "core:log"
import "core:os"
import "core:text/match"

VERSION_REGEX :: "[0-9]\\.[0-9]{1,2}\\.[0-9]{1,3}"

// TODO: figure out how odin implements short flags
Program_Options :: struct {
	delete:    bool `usage:"Delete files that doesn't have the same version as the currently chosen kernel"`,
	update:    bool `usage:"Update limine config according to /usr/src/linux version"`,
	no_backup: bool `usage:"!!DISABLE!! limine config backup. Ignored if used without -update flag"`,
	verbose:   bool `usage:"Verbose logging"`,
}

main :: proc() {
	opts: Program_Options
	flags.parse_or_exit(&opts, os.args, .Odin)

	// stupid odin doesnt let me put it in an if scope........
	context.logger = log.create_console_logger(opts.verbose ? .Debug : .Info)
	log.debug(opts)

	if !opts.delete && !opts.update {
		log.info("At least one of -update or -delete flags is required")
		return
	}

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

	kernel_version, kernel_matched := match_kernel_version(real_path)
	if !kernel_matched {
		log.error("Failed to find kernel version in /usr/src/linux symlink")
		os.exit(1)
	}

	if opts.update {
		new_config, updated := update_config(kernel_version)

		if updated && prompt_config(new_config) {
			if !opts.no_backup {
				backup_ok := backup_limine_config()
				if !backup_ok {
					log.error("failed to backup limine.conf")
					os.exit(1)
				}
			}
			write_ok := write_new_config(new_config)
			if !write_ok {
				log.error("failed to write new config to /boot/limine.conf")
			}
		} else {
			log.info("config remains unchanged")
		}
	}

	if opts.delete {
		log.debug("deleting unrelated files from /boot")
		delete_unrelated_files(kernel_version)
	}
}

delete_unrelated_files :: proc(kernel_version: string) {
	boot_files, boot_dir_err := os.read_all_directory_by_path("/boot", context.allocator)
	if boot_dir_err != nil {
		log.error("Failed to read directory:", boot_dir_err)
		os.exit(1)
	}
	defer delete(boot_files)

	for file in boot_files {
		file_version, matched := match_kernel_version(file.name)
		if !matched {
			continue
		}

		if file_version != kernel_version {
			log.debugf("%v doesn't match versions with %v", file.name, kernel_version)
			log.warnf("deleting %v", file.fullpath)
			// delete_file_as_root(file.fullpath)
		}
	}
}

prompt_config :: proc(new_config: string) -> (accepted: bool) {
	fmt.println()
	fmt.println(new_config)
	fmt.print("\nDo you accept the new config? [y/N]: ")

	buffer: [1]byte
	os.read(os.stdin, buffer[:])

	// 121 = y
	// 89  = Y
	// only handling y cuz everything else will be
	// defaulted to "no" as the answer
	if buffer[0] == 121 || buffer[0] == 89 {
		accepted = true
	}

	return
}

match_kernel_version :: proc(haystack: string) -> (matched: string, found: bool) {
	// NOTE: matches even 298018931.29838123.89023108923
	// no im not using regex its BROKEN IN ODIN
	matcher := match.matcher_init(haystack, "%d+%.%d+%.%d+")
	return match.matcher_match(&matcher)
}

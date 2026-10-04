package main

import "core:log"
import "core:os"

is_using_doas :: proc() -> bool {
	if os.exists("/bin/doas") {
		return true
	}
	return false
}

backup_limine_config :: proc() -> (ok: bool) {
	su_util := is_using_doas() ? "doas" : "sudo"

	log.info("Copying /boot/limine.conf as root")
	_, _, _, process_err := os.process_exec(
		{
			// command = {su_util, "cp", "/boot/limine.conf", "/boot/testingmeowing.backup"},
			command = {su_util, "cp", "/boot/limine.conf", "/boot/limine.conf.backup"},
		},
		context.allocator,
	)

	if process_err != nil {
		log.error("failed to backup /boot/limine.conf:", process_err)
		return
	}

	return true
}

write_new_config :: proc(content: string) -> (ok: bool) {
	su_util := is_using_doas() ? "doas" : "sudo"

	// open stdout and stdin
	r, w, pipe_err := os.pipe()
	if pipe_err != nil {
		log.error("failed to create pipes:", pipe_err)
		return
	}

	log.info("Writting to /boot/limine.conf as root")
	process, process_err := os.process_start(
	{
		// command = { su_util, "tee", "/boot/testingmeowing" },
		command = {su_util, "tee", "/boot/limine.conf"},
		stdin   = r,
		stdout  = os.stdout,
		stderr  = os.stderr,
	},
	)
	if process_err != nil {
		log.error("failed to open process:", process_err)
		os.close(r)
		os.close(w)
		return
	}

	os.close(r) // my pipe parent aint reading this shi😂😂😂 (i copied those from unicode.org dont tell me im an ai please im human please im begging)

	_, write_err := os.write_string(w, content)
	if write_err != nil {
		log.error("failed to write to stdin:", write_err)
		return
	}
	os.close(w)

	state, wait_err := os.process_wait(process)
	if wait_err != nil {
		log.error("failed to wait for process:", wait_err)
		return
	}

	return true
}

delete_file_as_root :: proc(path: string) -> (ok: bool) {
	su_util := is_using_doas() ? "doas" : "sudo"

	log.infof("Deleting %v as root", path)
	_, _, _, process_err := os.process_exec({command = {su_util, "rm", path}}, context.allocator)

	if process_err != nil {
		log.errorf("failed to delete %v: %v", path, process_err)
		return
	}

	return true
}

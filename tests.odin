package main

import "core:log"
import "core:os"
import "core:testing"
import "core:text/match"

@(test)
version_match_test :: proc(t: ^testing.T) {
	real_path, _ := os.read_link("/usr/src/linux", context.allocator)
	log.info(real_path)
	testing.expect(t, real_path == "linux-6.18.50-gentoo-dist-bin")

	matcher := match.matcher_init(real_path, "%d+%.%d+%.%d+")
	word, ok := match.matcher_match(&matcher)

	testing.expect(t, ok)
	log.info(word)
	testing.expect(t, word == "6.18.50")
}

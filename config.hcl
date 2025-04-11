group "default" {
	targets = ["debian-latest", "alpine-latest", "debian-12", "debian-11", "debian-10", "debian-9_6", "debian-9_5", "alpine-12", "alpine-11", "alpine-10", "alpine-9_6", "alpine-9_5"]
}

variable "BUILDREV" {
	default = ""
}

target "common" {
	platforms = ["linux/amd64", "linux/arm64", "linux/arm/v7", "linux/s390x", "linux/ppc64le"]
	args = {"GOCRONVER" = "v0.0.10"}
}

target "debian" {
	inherits = ["common"]
	dockerfile = "debian.Dockerfile"
}

target "alpine" {
	inherits = ["common"]
	dockerfile = "alpine.Dockerfile"
}

target "debian-latest" {
	inherits = ["debian"]
	args = {"BASETAG" = "13"}
	tags = [
		"mattiabiondani/postgres-backup-local:latest",
		"mattiabiondani/postgres-backup-local:13",
		notequal("", BUILDREV) ? "mattiabiondani/postgres-backup-local:13-debian-${BUILDREV}" : ""
	]
}

target "alpine-latest" {
	inherits = ["alpine"]
	args = {"BASETAG" = "13-alpine"}
	tags = [
		"mattiabiondani/postgres-backup-local:alpine",
		"mattiabiondani/postgres-backup-local:13-alpine",
		notequal("", BUILDREV) ? "mattiabiondani/postgres-backup-local:13-alpine-${BUILDREV}" : ""
	]
}

target "debian-12" {
	inherits = ["debian"]
	args = {"BASETAG" = "12"}
	tags = [
		"mattiabiondani/postgres-backup-local:12",
		notequal("", BUILDREV) ? "mattiabiondani/postgres-backup-local:12-debian-${BUILDREV}" : ""
	]
}

target "alpine-12" {
	inherits = ["alpine"]
	args = {"BASETAG" = "12-alpine"}
	tags = [
		"mattiabiondani/postgres-backup-local:12-alpine",
		notequal("", BUILDREV) ? "mattiabiondani/postgres-backup-local:12-alpine-${BUILDREV}" : ""
	]
}

target "debian-11" {
	inherits = ["debian"]
	args = {"BASETAG" = "11"}
	platforms = ["linux/amd64", "linux/arm64"]  # Limit to supported platforms
	tags = [
		"mattiabiondani/postgres-backup-local:11",
		notequal("", BUILDREV) ? "mattiabiondani/postgres-backup-local:11-debian-${BUILDREV}" : ""
	]
}

target "alpine-11" {
	inherits = ["alpine"]
	args = {"BASETAG" = "11-alpine"}
	tags = [
		"mattiabiondani/postgres-backup-local:11-alpine",
		notequal("", BUILDREV) ? "mattiabiondani/postgres-backup-local:11-alpine-${BUILDREV}" : ""
	]
}

target "debian-10" {
	inherits = ["debian"]
	args = {"BASETAG" = "10"}
	platforms = ["linux/amd64", "linux/arm64"]  # Limit to supported platforms
	tags = [
		"mattiabiondani/postgres-backup-local:10",
		notequal("", BUILDREV) ? "mattiabiondani/postgres-backup-local:10-debian-${BUILDREV}" : ""
	]
}

target "alpine-10" {
	inherits = ["alpine"]
	args = {"BASETAG" = "10-alpine"}
	tags = [
		"mattiabiondani/postgres-backup-local:10-alpine",
		notequal("", BUILDREV) ? "mattiabiondani/postgres-backup-local:10-alpine-${BUILDREV}" : ""
	]
}

target "debian-9_6" {
	inherits = ["debian"]
	args = {"BASETAG" = "9.6"}
	platforms = ["linux/amd64", "linux/arm64"]  # Limit to supported platforms
	tags = [
		"mattiabiondani/postgres-backup-local:9.6",
		notequal("", BUILDREV) ? "mattiabiondani/postgres-backup-local:9.6-debian-${BUILDREV}" : ""
	]
}

target "alpine-9_6" {
	inherits = ["alpine"]
	args = {"BASETAG" = "9.6-alpine"}
	tags = [
		"mattiabiondani/postgres-backup-local:9.6-alpine",
		notequal("", BUILDREV) ? "mattiabiondani/postgres-backup-local:9.6-alpine-${BUILDREV}" : ""
	]
}

target "debian-9_5" {
	inherits = ["debian"]
	args = {"BASETAG" = "9.5"}
	platforms = ["linux/amd64", "linux/arm64"]  # Limit to supported platforms
	tags = [
		"mattiabiondani/postgres-backup-local:9.5",
		notequal("", BUILDREV) ? "mattiabiondani/postgres-backup-local:9.5-debian-${BUILDREV}" : ""
	]
}

target "alpine-9_5" {
	inherits = ["alpine"]
	args = {"BASETAG" = "9.5-alpine"}
	tags = [
		"mattiabiondani/postgres-backup-local:9.5-alpine",
		notequal("", BUILDREV) ? "mattiabiondani/postgres-backup-local:9.5-alpine-${BUILDREV}" : ""
	]
}

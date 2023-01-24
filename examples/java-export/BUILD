load("@rules_jvm_external//:defs.bzl", "java_export", "maven_bom","maven_publish")

# To export the file, run:
#
# `bazel run //:example-export.publish --define "maven_repo=file://$(pwd)/repository"`
#
# GPG signing will be enabled if you also define `gpg_sign=true`, `maven_user`, and
# `maven_password`

java_export(
    name = "example-export",
    extra_artifacts = {
        "release": "//src/main/java/com/github/bazelbuild/rulesjvmexternal/example/export:tar",
    },
    maven_coordinates = "com.example:bazel-example:$(version)",
    runtime_deps = [
        "//src/main/java/com/github/bazelbuild/rulesjvmexternal/example/export",
    ],
)

maven_publish(
    name="artifact-publish",
    artifact_jar="//src/main/java/com/github/bazelbuild/rulesjvmexternal/example/export:tar",
    coordinates = "com.example:artifact-example:$(version)",
)

maven_bom(
    name = "bom",
    dependencies_maven_coordinates = "com.example:bazel-example-dependencies:0.0.1",
    java_exports = [
        ":example-export",
        "//src/main/java/com/github/bazelbuild/rulesjvmexternal/example/io",
    ],
    maven_coordinates = "com.example:bazel-example-bom:0.0.1",
)

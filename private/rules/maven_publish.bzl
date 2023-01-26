MavenPublishInfo = provider(
    fields = {
        "coordinates": "Maven coordinates for the project, which may be None",
        "pom": "Pom.xml file for metdata",
        "javadocs": "Javadoc jar file for documentation files",
        "artifact": "Jar with the code or generic artifact like .war and metadata for execution",
        "source_jar": "Jar with the source code for review",
        "extra_classifiers": "Extra classifiers for Artifacts",
        "extra_artifacts": "Extra artifacts such as tars, wars",
    },
)

_TEMPLATE = """#!/usr/bin/env bash

echo "Uploading {coordinates} to {maven_repo}"
{uploader} {maven_repo} {gpg_sign} {user} {password} {coordinates} {pom} {artifact} {source_jar} {javadoc} {extra_classifiers} {extra_artifacts}
"""

def _maven_publish_impl(ctx):
    executable = ctx.actions.declare_file("%s-publisher" % ctx.attr.name)

    maven_repo = ctx.var.get("maven_repo", "''")
    gpg_sign = ctx.var.get("gpg_sign", "'false'")
    user = ctx.var.get("maven_user", "''")
    password = ctx.var.get("maven_password", "''")

    # Expand maven coordinates for any variables to be replaced.
    coordinates = ctx.expand_make_variables("coordinates", ctx.attr.coordinates, ctx.var)
    artifacts_short_path = ctx.file.artifact.short_path if ctx.file.artifact else "''"
    source_short_path = ctx.file.source_jar.short_path if ctx.file.source_jar else "''"
    javadocs_short_path = ctx.file.javadocs.short_path if ctx.file.javadocs else "''"
    extra_artifacts = [file.short_path for file in ctx.files.extra_artifacts]

    ctx.actions.write(
        output = executable,
        is_executable = True,
        content = _TEMPLATE.format(
            uploader = ctx.executable._uploader.short_path,
            coordinates = coordinates,
            gpg_sign = gpg_sign,
            maven_repo = maven_repo,
            password = password,
            user = user,
            pom = ctx.file.pom.short_path if ctx.file.pom else "''",
            artifact = artifacts_short_path,
            source_jar = source_short_path,
            javadoc = javadocs_short_path,
            extra_classifiers = ",".join(ctx.attr.extra_classifiers),
            extra_artifacts = ",".join(extra_artifacts),
        ),
    )

    files = [] + ctx.files.extra_artifacts
    if ctx.file.pom:
        files.append(ctx.file.pom)
    if ctx.file.artifact:
        files.append(ctx.file.artifact)
    if ctx.file.source_jar:
        files.append(ctx.file.source_jar)
    if ctx.file.javadocs:
        files.append(ctx.file.javadocs)

    return [
        DefaultInfo(
            files = depset([executable]),
            executable = executable,
            runfiles = ctx.runfiles(
                files = files,
                collect_data = True,
            ).merge(ctx.attr._uploader[DefaultInfo].data_runfiles),
        ),
        MavenPublishInfo(
            coordinates = coordinates,
            artifact = ctx.file.artifact,
            javadocs = ctx.file.javadocs,
            source_jar = ctx.file.source_jar,
            pom = ctx.file.pom,
        ),
    ]

maven_publish = rule(
    _maven_publish_impl,
    doc = """Publish artifacts to a maven repository.

The maven repository may accessed locally using a `file://` URL, or
remotely using an `https://` URL. The following flags may be set
using `--define`:

  gpg_sign: Whether to sign artifacts using GPG
  maven_repo: A URL for the repo to use. May be "https" or "file".
  maven_user: The user name to use when uploading to the maven repository.
  maven_password: The password to use when uploading to the maven repository.

When signing with GPG, the current default key is used.
""",
    executable = True,
    attrs = {
        "coordinates": attr.string(
            mandatory = True,
        ),
        "pom": attr.label(
            allow_single_file = True,
        ),
        "javadocs": attr.label(
            allow_single_file = True,
        ),
        "artifact": attr.label(
            allow_single_file = True,
        ),
        "source_jar": attr.label(
            allow_single_file = True,
        ),
        "extra_classifiers": attr.string_list(),
        "extra_artifacts": attr.label_list(),
        "_uploader": attr.label(
            executable = True,
            cfg = "exec",
            default = "//private/tools/java/com/github/bazelbuild/rules_jvm_external/maven:MavenPublisher",
            allow_files = True,
        ),
    },
)

import argparse
import os
import platform
import subprocess
import stat

from typing import List


def setup_docker_image(target_arch: str, project_dir: str) -> str:
    extensions_dir = os.path.join(project_dir, "extensions")
    docker_file = os.path.join(extensions_dir, "cross_compile_stuff", "Dockerfile.{}".format(target_arch))
    docker_image = "openchamp_{}_cross".format(target_arch)

    # Create the compile docker image
    subprocess.call(
        ["docker", "build", "-t", docker_image, "-f", docker_file, "."],
        cwd=project_dir
    )

    # run the docker image and capture the output
    docker_result = subprocess.run(
        ["docker", "run", docker_image],
        cwd=project_dir,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE
    )

    compiler_script = os.path.join(extensions_dir, "cross_compile_stuff", "{}.sh".format(target_arch))
    with open(compiler_script, "w") as f:
        f.write(docker_result.stdout.decode("utf-8"))

    os.chmod(compiler_script, os.stat(compiler_script).st_mode | stat.S_IXUSR)

    return compiler_script


if __name__ == "__main__":
    script_dir = os.path.abspath(os.path.dirname(os.path.realpath(__file__)))
    extensions_dir = os.path.join(script_dir, "..")
    project_dir = os.path.join(extensions_dir, "..")
    default_api_file = os.path.join(extensions_dir, "godot-cpp", "gdextension", "extension_api.json")

    host_os = platform.system()
    host_arch = platform.machine()

    parser = argparse.ArgumentParser(
        description="compile the gdextension"
    )

    parser.add_argument(
        "--mode",
        type=str,
        default="debug",
        choices=["release", "debug"],
        help="The compilation mode (default: debug)",
        dest="build_mode"
    )

    parser.add_argument(
        "--api_file",
        type=str,
        default=default_api_file,
        help="The API file to use (default: {})".format(default_api_file)
    )
    
    parser.add_argument(
        "--target_arch",
        type=str,
        default=host_arch,
        help="The target architecture (default: {})".format(host_arch)
    )

    parser.add_argument(
        "--build_dir",
        type=str,
        required=False,
        help="The build directory (default: build_<target_arch>_<build_mode>)"
    )

    args = vars(parser.parse_args())
    print(args)

    setup_command: List[str] = []
    compile_command: List[str] = []

    if host_arch == args["target_arch"]:
        print("Building natively for the host architecture ({})".format(host_arch))

        setup_command = ["cmake"]
        compile_command = ["ninja"]
    else:
        print("Building with docker for the target architecture: {}".format(args["target_arch"]))
        
        compiler_script = setup_docker_image(args["target_arch"], project_dir)
        compiler_script = os.path.abspath(compiler_script)

        setup_command = [compiler_script, "cmake"]
        compile_command = [compiler_script, "ninja"]

    # Set the build directory
    build_dir = os.path.join("extensions", "build_{}_{}".format(args["target_arch"], args["build_mode"]))
    if args["build_dir"]:
        build_dir = args["build_dir"]

    os.makedirs(build_dir, exist_ok=True)

    # Run the setup command
    setup_command.extend([
        "-DCMAKE_BUILD_TYPE={}".format(args["build_mode"].capitalize()),
        "-DGODOT_GDEXTENSION_API_FILE={}".format(args["api_file"]),
        "-B", build_dir,
        "-GNinja",
        "extensions"
    ])

    subprocess.call(setup_command, cwd=project_dir)

    # Compile the source file
    compile_command.extend([
        "-C", build_dir
    ])

    subprocess.call(compile_command, cwd=project_dir)

    # install the build output
    compile_command.append("install")

    subprocess.call(compile_command, cwd=project_dir)
    
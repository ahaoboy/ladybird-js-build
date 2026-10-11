if [ $# -ne 3 ]; then
    echo "Usage: $0 ARTIFACT_NAME TARGET GITHUB_TOKEN" >&2
    echo "  ARTIFACT_NAME  upstream artifact name, e.g. ladybird-js-Linux-x86_64" >&2
    echo "  TARGET         release target triple, e.g. x86_64-unknown-linux-gnu" >&2
    exit 1
fi

ARTIFACT_NAME="$1"
TARGET="$2"
GITHUB_TOKEN="$3"

# Latest successful run of the upstream "Package the js repl as a binary artifact" workflow on master.
RUN_ID=$(curl -H "Authorization: token $GITHUB_TOKEN" -s \
    "https://api.github.com/repos/LadybirdBrowser/ladybird/actions/workflows/js-and-wasm-artifacts.yml/runs?branch=master&status=success&per_page=1" | \
    jq -r '.workflow_runs[0].id')

if [ -z "$RUN_ID" ] || [ "$RUN_ID" = "null" ]; then
    echo "Error: Failed to find any recent ladybird-js build on LadybirdBrowser/ladybird" >&2
    exit 1
fi

echo "RUN_ID: $RUN_ID"
echo "ARTIFACT_NAME: $ARTIFACT_NAME"
echo "TARGET: $TARGET"

# nightly.link exposes an artifact as a zip keyed by the workflow run id and the artifact name.
download_url="https://nightly.link/LadybirdBrowser/ladybird/actions/runs/${RUN_ID}/${ARTIFACT_NAME}.zip"

echo "Download URL: $download_url"

curl -H "Accept: application/octet-stream" -L -o "${ARTIFACT_NAME}.zip" "$download_url"

# The zip contains the cpack tarball produced by the upstream workflow,
# e.g. ladybird-js-Linux-x86_64.zip -> ladybird-js-Linux-x86_64.tar.gz
unzip -o "${ARTIFACT_NAME}.zip"
rm -f "${ARTIFACT_NAME}.zip"

ladybird="ladybird-js-${TARGET}"
mv "${ARTIFACT_NAME}.tar.gz" "${ladybird}.tar.gz"

ls -lh "${ladybird}.tar.gz"

if [ $# -ne 3 ]; then
    echo "Usage: $0 ARTIFACT_NAME TARGET GITHUB_TOKEN" >&2
    exit 1
fi

ARTIFACT_NAME="$1"
GZ_NAME="$3"
TARGET="$2"
GITHUB_TOKEN="$4"

ARTIFACT_ID=$(curl -H "Authorization: token $GITHUB_TOKEN" -s "https://api.github.com/repos/ladybirdbrowser/ladybird/actions/artifacts" | \
    jq -r --arg name "$ARTIFACT_NAME" '.artifacts[] | select(.name == $name) | .id' | \
    head -n 1)

if [ -z "$ARTIFACT_ID" ]; then
    echo "Error: Failed to find any releases for $ARTIFACT_NAME on LadybirdBrowser/ladybird" >&2
    exit 1
fi

RUN_ID=$(curl -H "Authorization: token $GITHUB_TOKEN" -s "https://api.github.com/repos/ladybirdbrowser/ladybird/actions/runs?event=push&branch=master&status=success" | \
    jq -r '.workflow_runs[] | select(.name == "Package the js repl as a binary artifact") | .check_suite_id' | \
    sort -nr | \
    head -n 1)

if [ -z "$RUN_ID" ]; then
    echo "Error: Failed to find any recent ladybird-js build" >&2
    exit 1
fi

echo "RUN_ID: $RUN_ID"
echo "ARTIFACT_ID: $ARTIFACT_ID"
echo "ARTIFACT_NAME: $ARTIFACT_NAME"
echo "TARGET: $TARGET"

download_url="https://nightly.link/ladybirdbrowser/ladybird/suites/${RUN_ID}/artifacts/${ARTIFACT_ID}"

echo "Download URL: $download_url"

curl -H "Authorization: token $GITHUB_TOKEN" \
    -H "Accept: application/octet-stream" \
    -L -o "${ARTIFACT_NAME}" "$download_url"

unzip -j "${ARTIFACT_NAME}"

mkdir -p "$TARGET"

tar -xzf "${GZ_NAME}.tar.gz" -C "$TARGET"

mv "$TARGET/bin/js" "$TARGET/js"
rm -r "$TARGET/bin"

cd "$TARGET"
zip -r "../${TARGET}.zip" .

cd ..

echo "Done! Output zip file: ${TARGET}.zip"

latest_tag="$RUN_ID_$ARTIFACT_ID"
echo "tag=$latest_tag" >> $GITHUB_OUTPUT

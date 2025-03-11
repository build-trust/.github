# Get enrollment code
set -ex

if [[ -z $DOCKER_IMAGE_FOR_ENROLL || -z $EMAIL_ADDRESS ||  -z $SCRIPT_PATH ]]; then
    echo "Please set all variable DOCKER_IMAGE_FOR_ENROLL EMAIL_ADDRESS SCRIPT_PATH"
    exit 1
fi

sudo apt install expect || apt install expect
# export QUIET=1
export OCKAM_LOGGING=0
export OCKAM_OPENTELEMETRY_EXPORT=0
export OCKAM_DEFAULT_TIMEOUT=10m

ockam_enroll_log=$(mktemp)

ockam identity create default
unbuffer bash -c "echo | ockam enroll --identity default" | tee $ockam_enroll_log  &
process_id=$!

while true; do
    sleep 2
    log=$(cat $ockam_enroll_log)

    val=$(ps aux)

    if ! ps aux | grep "ockam enroll" >/dev/null; then
    cat $ockam_enroll_log
    exit 1
    fi

    regex="([A-Z]+\-[A-Z]+)"
    if [[ "$log" =~ $regex ]]; then
    enroll_code="${BASH_REMATCH[1]}"
    break
    fi
done

echo "Enroll code is => $enroll_code"

if which docker; then
    docker run --rm -e ACTIVATION_CODE="$enroll_code" -e SCRIPT_DIR="/artifacts-scripts" -e EMAIL_ADDRESS="$EMAIL_ADDRESS" -e HOST_USER_ID=$(id -u) "$DOCKER_IMAGE_FOR_ENROLL" python3 /artifacts-scripts/ockam_enroll.py || (cat geckodriver.log && exit 1)
else
    ACTIVATION_CODE="$enroll_code" SCRIPT_DIR="$SCRIPT_PATH" EMAIL_ADDRESS="$EMAIL_ADDRESS" python3 "$SCRIPT_PATH/ockam_enroll.py" || (cat geckodriver.log && exit 1)
fi

sleep 2
# Check for exit status
if ! wait $process_id; then
    echo "Ockam enroll failed"
    cat $ockam_enroll_log
    exit 1
fi

echo "Ockam enroll was a success"
cat $ockam_enroll_log

echo "calling project list again"
ockam project list

echo "calling project ticket"

###############################################################################
# Prevent Direct Execution
###############################################################################
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "This script is meant to be sourced, not executed directly."
    exit 1
fi

run_ai() {
    local output
    output=$(./bin/llama-cli -m ~/models/mistral-7b-instruct-v0.1.Q4_K_M.gguf -p "$1")

    echo "AI Suggested Command: $output"

    read -rp "Run this command? (y/n): " confirm
    if [[ "$confirm" == "y" ]]; then
        eval "$output"
    fi
}
ai_assistant() {
    local model_path="$HOME/models/mistral-7b-instruct-v0.1.Q4_K_M.gguf"
    local llama_bin="$HOME/Projects/llama.cpp/build/bin/llama-cli"
    if [ ! -f "$llama_bin" ]; then
        echo "Error: llama-cli binary not found at $llama_bin"
        return 1
    fi
    if [ ! -f "$model_path" ]; then
        echo "Error: Model not found at $model_path"
        return 1
    fi

    echo "🔹 AI Terminal Assistant is now running! Type 'exit' to quit."
    echo "🔹 Ask questions or request commands. If a command is generated, you can choose to run it."

    while true; do
        read -rp "🤖 AI> " user_input
        if [[ "$user_input" == "exit" ]]; then
            echo "Goodbye!"
            break
        fi

        # Get AI response
        response=$("$llama_bin" -m "$model_path" -p "$user_input" -c 1024 --n-gpu-layers 30)

        # Display AI response
        echo -e "🧠 AI Suggestion:\n$response"

        # Ask user if they want to run it
        if [[ "$response" =~ ^(ls|cd|mv|rm|cp|find|grep|sed|awk|cat|chmod|chown|tar|zip|unzip|mkdir|rmdir|df|du|ping|uptime|top|htop|neofetch|nvidia-smi|curl|wget|echo|date|whoami|pwd|ps|kill) ]]; then
            read -rp "Run this command? (y/n): " confirm
            if [[ "$confirm" == "y" ]]; then
                eval "$response"
            else
                echo "Command not executed."
            fi
        fi
    done
}

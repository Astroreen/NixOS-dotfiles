{ pkgs, ... }:

{
    services.ollama = {
        enable = true;
        package = pkgs.ollama-cuda;     # Use the CUDA-enabled Ollama package
        acceleration = "cuda";          # Enable CUDA acceleration
        host = "0.0.0.0";
        environmentVariables = {
            OLLAMA_HOST = "0.0.0.0:11434";
        };
    };
    
    home.sessionVariables = {
        OLLAMA_HOST = "0.0.0.0:11434";
    };
}

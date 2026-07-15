{ config, lib, ... }:
let
  servers = {
    context7 = {
      type = "http";
      url = "https://mcp.context7.com/mcp";
      headers = { };
      description = "For fetching relevant documentation";
    };

    playwright = {
      command = "docker";
      args = [
        "run"
        "-i"
        "--rm"
        "mcp/playwright"
      ];
      description = "Browser automation for web interactions";
    };

    youtube-transcript = {
      command = "docker";
      args = [
        "run"
        "-i"
        "--rm"
        "mcp/youtube-transcript"
      ];
      description = "Fetch YouTube video transcripts";
    };

    persistent-memory = {
      command = "npx";
      args = [
        "-y"
        "@modelcontextprotocol/server-memory"
      ];
      env = {
        MEMORY_FILE_PATH = "${config.xdg.configHome}/mcp/memory.jsonl";
      };
      description = "Persistent memory across sessions";
    };

    sequential-thinking = {
      command = "npx";
      args = [
        "-y"
        "@modelcontextprotocol/server-sequential-thinking"
      ];
      description = "Chain-of-thought reasoning";
    };

    magic-ui-components = {
      command = "npx";
      args = [
        "-y"
        "@magicuidesign/mcp@latest"
      ];
      description = "React components";
    };

    token-optimizer = {
      command = "npx";
      args = [
        "-y"
        "token-optimizer-mcp"
      ];
      description = "Token optimization for 95%+ context reduction via content deduplication and compression in session";
    };

    cloudflare-docs = {
      type = "http";
      url = "https://docs.mcp.cloudflare.com/mcp";
      description = "Cloudflare documentation search";
    };

    excel = {
      command = "uvx";
      args = [
        "excel-mcp-server"
        "stdio"
      ];
      description = "Excel spreadsheet interactions";
    };

    drawio = {
      command = "npx";
      args = [
        "-y"
        "@drawio/mcp"
      ];
      description = "Draw.io diagram interactions";
    };
  };
in
{
  programs.mcp = {
    enable = true;
    servers = lib.mapAttrs (_: v: { disabled = lib.mkDefault true; } // v) servers;
  };
}

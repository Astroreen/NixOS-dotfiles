{ config, ... }:
{
  programs.mcp = {
    enable = true;
    servers = {
      context7 = {
        disabled = true;
        url = "https://mcp.context7.com/mcp";
        headers = { };
        description = "For fetching relevant documentation";
      };

      playwright = {
        disabled = true;
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
        disabled = true;
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
        disabled = false;
        command = "npx";
        args = [
          "-y"
          "@modelcontextprotocol/server-memory"
        ];
        env = {
          MEMORY_FILE_PATH =  "${config.xdg.configHome}/mcp/memory.jsonl";
        };
        description = "Persistent memory across sessions";
      };

      sequential-thinking = {
        disabled = true;
        command = "npx";
        args = [
          "-y"
          "@modelcontextprotocol/server-sequential-thinking"
        ];
        description = "Chain-of-thought reasoning";
      };

      magic-ui-components = {
        disabled = true;
        command = "npx";
        args = [
          "-y"
          "@magicuidesign/mcp@latest"
        ];
        description = "React components";
      };

      token-optimizer = {
        disabled = true;
        command = "npx";
        args = [
          "-y"
          "token-optimizer-mcp"
        ];
        description = "Token optimization for 95%+ context reduction via content deduplication and compression in session";
      };

      cloudflare-docs = {
        disabled = true;
        type = "http";
        url = "https://docs.mcp.cloudflare.com/mcp";
        description = "Cloudflare documentation search";
      };
    };
  };
}

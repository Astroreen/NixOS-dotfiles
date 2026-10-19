{
  atlas = {
    description = "Master Orchestrator - coordinates tasks and verification";
    mode = "all";
    temperature = 0;
    color = "#3498DB";
  };
  explore = {
    description = "Contextual grep for codebases. Answers \"Where is X?\", \"Which file has Y?\", \"Find the code that does Z\". Specify thoroughness: \"quick\" for basic, \"medium\" for moderate, \"very thorough\" for comprehensive analysis.";
    mode = "subagent";
    temperature = 0.1;
    color = "#2ECC71";
    tools = {
      bash = true;
      edit = false;
      glob = true;
      grep = true;
      lsp = true;
      read = true;
      write = false;
    };
  };
  hephaestus = {
    description = "Autonomous Deep Worker - senior staff engineer persona";
    mode = "subagent";
    temperature = 0;
    color = "#FF6B35";
  };
  librarian = {
    description = "Specialized codebase understanding agent for multi-repository analysis, searching remote codebases, retrieving official documentation, and finding implementation examples.";
    mode = "subagent";
    temperature = 0.1;
    color = "#1ABC9C";
    tools = {
      bash = true;
      edit = false;
      glob = true;
      grep = true;
      read = true;
      webfetch = true;
      websearch = true;
      write = false;
    };
  };
  metis = {
    description = "Pre-planning Consultant - analyzes intent and risks";
    mode = "subagent";
    temperature = 0;
    color = "#F1C40F";
  };
  momus = {
    description = "Plan Reviewer - verifies executability and references";
    mode = "subagent";
    temperature = 0;
    color = "#E67E22";
  };
  multimodal-looker = {
    description = "Media Interpreter - analyzes images and documents";
    mode = "subagent";
    temperature = 0;
    color = "#E91E63";
    tools = {
      bash = false;
      edit = false;
      read = true;
      write = false;
    };
  };
  oracle = {
    description = "Read-only consultation agent. High-IQ reasoning specialist for debugging hard problems and high-difficulty architecture design.";
    mode = "subagent";
    temperature = 0.1;
    color = "#E74C3C";
    tools = {
      bash = true;
      edit = false;
      glob = true;
      grep = true;
      lsp = true;
      read = true;
      write = false;
    };
  };
  prometheus = {
    description = "Planning consultant. Gathers information, gives best practices, and writes decision-complete work plans.";
    mode = "all";
    temperature = 0.1;
    color = "#9B59B6";
    tools = {
      bash = true;
      edit = false;
      glob = true;
      grep = true;
      read = true;
      task = true;
      webfetch = true;
      websearch = true;
      write = false;
    };
  };
  scribe = {
    description = "Scribe - document writer (docx/doc/pdf), example analysis, Lithuanian format defaults";
    mode = "all";
    temperature = 0.3;
    color = "#A29BFE";
  };
  sisyphus = {
    description = "Master Orchestrator - coordinates tasks and verification";
    mode = "all";
    temperature = 0.1;
    color = "#00CED1";
  };
  sisyphus-junior = {
    description = "Focused Task Executor - direct implementation";
    mode = "subagent";
    temperature = 0;
    color = "#16A085";
  };
}

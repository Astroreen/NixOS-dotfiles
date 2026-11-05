{
  code-review = {
    description = "Review a diff for correctness, edge cases, and regressions. One line per finding with location, problem, and fix.";
  };
  commit-message = {
    description = "Generate a Conventional Commits message from the staged diff. Subject <=50 chars, body only when the \"why\" is not obvious.";
  };
  design-taste-frontend = {
    description = "Anti-slop frontend skill for landing pages, portfolios, and redesigns. The agent reads the brief, infers the right design direction, and ships interfaces that do not look templated. Real design systems when applicable, audit-first on redesigns, strict pre-flight check.";
  };
  docx = {
    description = "Create, read, edit and verify Word documents (.docx) with local CLI tools only — LibreOffice, unzip/zip, no pandoc required. Use when producing or inspecting .docx/.doc files.";
  };
  frontend-design = {
    description = "Guidance for distinctive, intentional visual design when building new UI or reshaping an existing one. Helps with aesthetic direction, typography, and making choices that don't read as templated defaults.";
    license = "Complete terms in LICENSE.txt";
  };
  spike = {
    description = "Throwaway experiments to validate an idea before build.";
    license = "MIT";
    metadata = {
      astrocode = {
        tags = [
          "spike"
          "prototype"
          "experiment"
          "feasibility"
          "throwaway"
          "exploration"
          "research"
          "planning"
          "mvp"
          "proof-of-concept"
        ];
        related_skills = [
          "sketch"
          "writing-plans"
          "subagent-driven-development"
          "plan"
        ];
      };
    };
    extra = {
      version = "1.0.0";
      author = "Adapted from gsd-build/get-shit-done (MIT)";
    };
  };
  subagent-driven-development = {
    description = "Execute plans via subagents with a two-stage review (spec then quality).";
    license = "MIT";
    metadata = {
      astrocode = {
        tags = [
          "delegation"
          "subagent"
          "implementation"
          "workflow"
          "parallel"
        ];
        related_skills = [
          "writing-plans"
          "requesting-code-review"
          "test-driven-development"
        ];
      };
    };
    extra = {
      version = "1.1.0";
      author = "Adapted from obra/superpowers (MIT)";
    };
  };
  systematic-debugging = {
    description = "4-phase root cause debugging: understand bugs before fixing.";
    license = "MIT";
    metadata = {
      astrocode = {
        tags = [
          "debugging"
          "troubleshooting"
          "problem-solving"
          "root-cause"
          "investigation"
        ];
        related_skills = [
          "test-driven-development"
          "writing-plans"
          "subagent-driven-development"
        ];
      };
    };
    extra = {
      version = "1.1.0";
      author = "Adapted from obra/superpowers (MIT)";
    };
  };
  test-driven-development = {
    description = "TDD: enforce RED-GREEN-REFACTOR, tests before code.";
    license = "MIT";
    metadata = {
      astrocode = {
        tags = [
          "testing"
          "tdd"
          "development"
          "quality"
          "red-green-refactor"
        ];
        related_skills = [
          "systematic-debugging"
          "writing-plans"
          "subagent-driven-development"
        ];
      };
    };
    extra = {
      version = "1.1.0";
      author = "Adapted from obra/superpowers (MIT)";
    };
  };
  orchestrate = {
    description = "Orchestrator role — split work into groups, run one T3 thread per group, keep every PR moving (no stalls on missing GitHub events), merge what the owner allowed. Use when the owner says \"ты оркестратор\", \"раздай по тредам\", \"сгруппируй задачи\", or the work needs several parallel threads.";
  };
  night-shift = {
    description = "Owner goes offline: standing permission to merge, decide and deploy until done, then one morning report.";
    disableModelInvocation = true;
  };
  annotations = {
    description = "Triage a batch of T3 preview annotations — classify, answer questions first, group into PRs, verify each fix in the preview. Use when a message carries several `preview-annotation` links.";
  };
  catch-up = {
    description = "Recap of a thread for an owner who forgot it — what was asked, done, decided, how it works now, what waits for them; optional before/after screenshots. Use for \"я забыл\", \"что было сделано\", \"что осталось\", \"покажи картинками\".";
  };
  changes-page = {
    description = "Before/after PDF of a branch or a batch of PRs — per change what it is, was/now, why, paired screenshots with red frames, how to use; bookmarks per change; a claude.ai page on request. Use for \"покажи, что изменилось\", \"до и после\", \"страница/артефакт с изменениями\".";
  };
  tips = {
    description = "Cheat sheet of my skills and T3 Code features, with how to ask for each.";
    disableModelInvocation = true;
  };
  timesheet = {
    description = "Fill the freelance hours .xlsx from PRs, commits and T3 threads without ever changing the hours.";
    disableModelInvocation = true;
  };
  unslop = {
    description = "Cut AI tells from any writing.";
    disableModelInvocation = true;
  };
  verify-before-done = {
    description = "Evidence gate checklist before claiming a task is done. Run tests and typecheck, report observed output faithfully, never claim done without evidence.";
  };
}

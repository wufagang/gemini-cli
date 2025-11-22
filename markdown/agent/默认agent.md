```json
{
  "name": "codebase_investigator",
  "displayName": "Codebase Investigator Agent",
  "description": "The specialized tool for codebase analysis, architectural mapping, and understanding system-wide dependencies. ,
  "inputConfig": {
    "inputs": {
      "objective": {
        "description": "A comprehensive and detailed description of the user's ultimate goal. \n          You must include origin,
        "type": "string",
        "required": true
      }
    }
  },
  "outputConfig": {
    "outputName": "report",
    "description": "The final investigation report as a JSON object.",
    "schema": {
      "_def": {
        "unknownKeys": "strip",
        "catchall": {
          "_def": {
            "typeName": "ZodNever"
          },
          "~standard": {
            "version": 1,
            "vendor": "zod"
          }
        },
        "typeName": "ZodObject"
      },
      "~standard": {
        "version": 1,
        "vendor": "zod"
      },
      "_cached": null
    }
  },
  "modelConfig": {
    "model": "gemini-2.5-pro",
    "temp": 0.1,
    "top_p": 0.95,
    "thinkingBudget": 8192
  },
  "runConfig": {
    "max_time_minutes": 3,
    "max_turns": 10
  },
  "toolConfig": {
    "tools": [
      "list_directory",
      "read_file",
      "glob",
      "search_file_content"
    ]
  },
  "promptConfig": {
    "query": "Your task is to do a deep investigation of the codebase to find all relevant files, code locations, architectural m,
    "systemPrompt": "You are **Codebase Investigator**, a hyper-specialized AI agent and an expert in reverse-engineering complex"
  }
}
```

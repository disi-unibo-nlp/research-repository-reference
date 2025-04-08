from huggingface_hub import hf_hub_download
from vllm import LLM, SamplingParams
from transformers import AutoTokenizer

from tqdm import tqdm
import json
import logging


logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

def run_inference(model_path, 
                  tokenizer,
                  output_file : str = "generated_outputs.jsonl",
                  batch_size : int = 8,
                  temperature : float = 0.1,
                  max_tokens : int = 2048):
    """
    Run inference with the VLLM library.
    """
    
    logger.info(f"Loading model: {model_path}")
    
    # Create an LLM.
    llm = LLM(model=model_path, 
              tokenizer=tokenizer)
    logger.info("Model loaded successfully")

    # Set the sampling parameters.
    sampling_params = SamplingParams(temperature=temperature, 
                                     max_tokens=max_tokens)


    # Sample prompts
    logger.info("Creating sample prompts")
    prompts = [
        "How many helicopters can a human eat in one sitting?",
        "What's the future of AI?",
    ]
    prompts = [[{"role": "user", "content": prompt}] for prompt in prompts]
    
    
    tokenizer_model = AutoTokenizer.from_pretrained(tokenizer, trust_remote_code=True)
    chat_templated_prompts = [tokenizer_model.apply_chat_template(p, 
                                                                  tokenize=False, 
                                                                  add_generation_prompt=True)
                              for p in prompts]
    
    # Create batches
    num_batches = (len(chat_templated_prompts) + batch_size - 1) // batch_size
    batched_prompts = [chat_templated_prompts[i*batch_size:(i+1)*batch_size] for i in range(num_batches)]

    
    
    logger.info("Starting inference")
    # Process the batches
    for batch_id, batch in tqdm(enumerate(batched_prompts), total=len(batched_prompts), desc="Processing batches", unit="batch"):
        # Generate the outputs.
        outputs = llm.generate(batch, sampling_params)
        
        # Print the outputs.
        for sample_id, output in enumerate(outputs):
            prompt = output.prompt
            generated_text = output.outputs[0].text
            # save to file in jsonl
            with open(output_file, "a") as f:
                for out in output.outputs:
                    generated_text = out.text
                    # Save the prompt and generated text to a file
                    json.dump({
                        "ID": (batch_id*batch_size)+sample_id, 
                        "generated_text": generated_text
                    }, f)
                    f.write("\n")
    



if __name__ == "__main__":

    tokenizer = "microsoft/phi-4"

    # For quantized models (GGUF, AWQ, ..)
    repo_id = "unsloth/phi-4-GGUF"
    filename = "phi-4-Q4_K_M.gguf"
    
    model = hf_hub_download(repo_id, filename=filename)

    # For full precision models
    model = "microsoft/phi-4"
    
    run_inference(model, tokenizer)
 
 
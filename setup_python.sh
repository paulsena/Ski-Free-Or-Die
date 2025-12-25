#!/bin/bash

# Create virtual environment if it doesn't exist
if [ ! -d ".venv" ]; then
    echo "Creating virtual environment in .venv..."
    python3 -m venv .venv
else
    echo "Virtual environment .venv already exists."
fi

# detailed instructions
echo ""
echo "Setup complete."
echo "To use 'python', activate the virtual environment by running:"
echo "source .venv/bin/activate"

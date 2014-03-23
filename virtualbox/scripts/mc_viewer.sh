#!/bin/bash

# Run vim but disable editing
vim -M -c 'map q :q<CR>' $@


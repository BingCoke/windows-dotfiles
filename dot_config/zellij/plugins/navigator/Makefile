# ============ 配置 ============
CRATE_NAME := navigator
OUT_DIR    := release

# ============ 目标 ============
.PHONY: build run clean optimize help

all: help

# 编译 wasm32-wasip1
build:
	cargo build --target wasm32-wasip1 --release
	@mkdir -p $(OUT_DIR)
	@cp target/wasm32-wasip1/release/$(CRATE_NAME).wasm $(OUT_DIR)/
	@echo ""
	@echo "========================================="
	@echo " Output: $(OUT_DIR)/$(CRATE_NAME).wasm"
	@echo " Size:   $$(du -h $(OUT_DIR)/$(CRATE_NAME).wasm | cut -f1)"
	@echo "========================================="

# 用 wasm-opt 优化体积（可选）
optimize: build
	@echo "=== Optimizing with wasm-opt ==="
	@wasm-opt -O3 -o $(OUT_DIR)/$(CRATE_NAME).wasm $(OUT_DIR)/$(CRATE_NAME).wasm
	@echo ""
	@echo "========================================="
	@echo " Optimized: $(OUT_DIR)/$(CRATE_NAME).wasm"
	@echo " Size:      $$(du -h $(OUT_DIR)/$(CRATE_NAME).wasm | cut -f1)"
	@echo "========================================="

# 用 wasmtime 运行
run: build
	wasmtime $(OUT_DIR)/$(CRATE_NAME).wasm

# 清理
clean:
	cargo clean
	@rm -rf $(OUT_DIR)
	@echo "=== Cleaned ==="

# 帮助
help:
	@echo ""
	@echo "  make build     - 编译 wasm32-wasip1 -> release/"
	@echo "  make optimize  - 编译并用 wasm-opt 优化"
	@echo "  make run       - 编译并用 wasmtime 运行"
	@echo "  make clean     - 清理所有产物"
	@echo ""


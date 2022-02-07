// Copyright lowRISC contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

// error_cmd test vseq
// test tries to capture error interrupt when cmd invalid condition appears
// cmd invalid is created when cmd sent and host isnt ready
class spi_host_error_cmd_vseq extends spi_host_tx_rx_vseq;
  `uvm_object_utils(spi_host_error_cmd_vseq)
  `uvm_object_new

  spi_segment_item segment;

  virtual task body();
    bit [7:0] read_q[$];
    bit [7:0] txqd;
    spi_host_intr_state_t intr_state;
    int num_transactions = 6;
    int cmdq_depth = 5;
    bit cmd_not_ready = 1'b0;

    csr_rd_check(.ptr(ral.error_enable), .compare_value(32'h1f));
    csr_wr(.ptr(ral.intr_enable), .value({TL_DW{1'b1}}));

    program_spi_host_regs();
    cfg.seq_cfg.host_spi_min_len = 4;
    cfg.seq_cfg.host_spi_max_len = 16;
    for (int i = 0; i < (cmdq_depth + 2); i++) begin
      generate_transaction();
      segment = new();
      if(i < (cmdq_depth + 1)) begin
        csr_rd_check(.ptr(ral.error_status.cmdbusy), .compare_value(0));
      end else begin
        csr_rd_check(.ptr(ral.error_status.cmdbusy), .compare_value(1));
      end
      while (transaction.segments.size() > 0) begin
        segment = transaction.segments.pop_back();
        if (segment.command_reg.direction != RxOnly) begin
          access_data_fifo(segment.spi_data, TxFifo,1'b0); // write tx fifo to overflow
        end
      end
      program_command_reg(segment.command_reg);
    end // endfor

    csr_rd_check(.ptr(ral.intr_state.error), .compare_value(1'b1));
  endtask : body

  virtual task generate_transaction();
    transaction_init();
    `DV_CHECK_RANDOMIZE_WITH_FATAL(transaction,num_segments == 2;)
  endtask

endclass : spi_host_error_cmd_vseq

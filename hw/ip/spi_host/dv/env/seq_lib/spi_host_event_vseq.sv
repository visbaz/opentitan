// Copyright lowRISC contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

// event test vseq
// sequence verifies all events occur in event_enable register
class spi_host_event_vseq extends spi_host_tx_rx_vseq;
  `uvm_object_utils(spi_host_event_vseq)
  `uvm_object_new

bit drain_rx;
spi_segment_item segment;
spi_host_intr_state_t intr_state;
int segms_size;
int segms_words;

constraint spi_ctrl_regs_c {
    // csid reg
    spi_host_ctrl_reg.csid inside {[0 : SPI_HOST_NUM_CS-1]};
    // control reg
    spi_host_ctrl_reg.tx_watermark == 5;
    spi_host_ctrl_reg.rx_watermark == 5;
  }

  virtual task body();
    segms_size = 0;
    segms_words = 0;
    cfg.seq_cfg.host_spi_min_len = 4;
    cfg.seq_cfg.host_spi_max_len = 16;
    csr_wr(.ptr(ral.intr_enable), .value(32'h2)); // interrupt enable for err and event
    csr_wr(.ptr(ral.event_enable), .value(32'h3f)); // enable event
    wait_ready_for_command();
    program_spi_host_regs();
    wait_ready_for_command();
    csr_rd_check(.ptr(ral.status.ready), .compare_value(1));
    wait_ready_for_command();
    send_txn();
    wait_ready_for_command();
    csr_rd_check(.ptr(ral.status.active), .compare_value(1));
    send_txn();
    if(segms_words >  spi_host_ctrl_reg.tx_watermark)
    csr_rd_check(.ptr(ral.status.txwm), .compare_value(1));
    send_txn();
    send_txn();
    csr_spinwait(.ptr(ral.status.active), .exp_data(1'b0));
    cfg.clk_rst_vif.wait_clks(100);
    csr_rd_check(.ptr(ral.status.txempty), .compare_value(1));
  endtask : body

  task send_txn(bit ready = 1);
  generate_transaction();
  segment = new();
  while (transaction.segments.size() > 0) begin
    segment = transaction.segments.pop_back();
  if (ready) wait_ready_for_command();
    if (segment.command_reg.direction != RxOnly) begin
      segms_size = segment.spi_data.size() + segms_size;
      segms_words = segms_size/4;
      access_data_fifo(segment.spi_data, TxFifo);
    end
   program_command_reg(segment.command_reg);
   if (ready) wait_ready_for_command();
  end
  endtask

  virtual task generate_transaction();
    transaction_init();
    `DV_CHECK_RANDOMIZE_WITH_FATAL(transaction,num_segments == 4;)
  endtask

endclass : spi_host_event_vseq


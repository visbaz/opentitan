// Copyright lowRISC contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

// error test vseq
// empty read error underflow
// write tx full fifo error overflow

class spi_host_error_txrx_vseq extends spi_host_tx_rx_vseq;
  `uvm_object_utils(spi_host_error_txrx_vseq)
  `uvm_object_new

  spi_segment_item segment;
  int txfifo_ptr = 0;
  int segms_size;

  virtual task body();
    bit [7:0] read_q[$];
    bit [7:0] txqd;
    spi_host_intr_state_t intr_state;

    csr_rd_check(.ptr(ral.error_enable), .compare_value(32'h1f));
    csr_spinwait(.ptr(ral.status.ready), .exp_data(1'b1));
    access_data_fifo(read_q, RxFifo, 1'b0); // attempting empty read error underflow
    cfg.clk_rst_vif.wait_clks(10);
    check_interrupts(.interrupts(1 << intr_state.error), .check_set(1));
    csr_rd_check(.ptr(ral.error_status.underflow), .compare_value(1)); // check underflow error

    program_spi_host_regs();
    csr_wr(.ptr(ral.configopts[0].clkdiv), .value(16'h28)); // clk div set to 20
    cfg.seq_cfg.host_spi_min_len = 4;
    cfg.seq_cfg.host_spi_max_len = 16;
    // loop for depth X no of bytes and 5 words short of SPI_HOST_TX_DEPTH
    while(txfifo_ptr < ((SPI_HOST_TX_DEPTH*4)-20)) begin
      generate_transaction();
      segment = new();
      segms_size = 0;
      if(txfifo_ptr < ((SPI_HOST_TX_DEPTH*4)-20)) begin
        csr_rd_check(.ptr(ral.error_status.overflow), .compare_value(0));
      end else begin
        csr_rd_check(.ptr(ral.error_status.overflow), .compare_value(1));
      end
      while (transaction.segments.size() > 0) begin
        segment = transaction.segments.pop_back();
        if (segment.command_reg.direction != RxOnly) begin
          segms_size = segment.spi_data.size() + segms_size;
          access_data_fifo(segment.spi_data, TxFifo,1'b0); // write tx fifo to overflow
        end
      end
      txfifo_ptr = segms_size + txfifo_ptr;
      program_command_reg(segment.command_reg);
    end // end while

    generate_transaction();
    segment = new();
    while (transaction.segments.size() > 0) begin
      segment = transaction.segments.pop_back();
      if (segment.command_reg.direction != RxOnly) begin
        access_data_fifo(segment.spi_data, TxFifo,1'b0); // write tx fifo to overflow
      end
    end
    csr_rd_check(.ptr(ral.error_status.overflow), .compare_value(1));
    csr_rd_check(.ptr(ral.intr_state.error), .compare_value(1'b1));
  endtask : body

endclass : spi_host_error_txrx_vseq

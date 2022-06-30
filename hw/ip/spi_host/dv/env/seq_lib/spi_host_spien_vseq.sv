// Copyright lowRISC contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

// spien test vseq
class spi_host_spien_vseq extends spi_host_tx_rx_vseq;
  `uvm_object_utils(spi_host_spien_vseq)
  `uvm_object_new

  virtual task body();
  bit spien = 1'b1;

    fork
      begin : isolation_fork
        fork
          start_reactive_seq();
        join_none

        begin
          wait_ready_for_command();
          for (int n = 0; n < 5; n++) begin
            start_spi_host_trans(1);
          end
            csr_wr(.ptr(ral.control.spien), .value(1'b0));
            cfg.clk_rst_vif.wait_clks($urandom_range(100000,200000));
            csr_wr(.ptr(ral.control.spien), .value(1'b1));
          for (int n = 0; n < 5; n++) begin
            start_spi_host_trans(1);
          end
          csr_spinwait(.ptr(ral.status.active), .exp_data(1'b0));
          csr_spinwait(.ptr(ral.status.rxqd), .exp_data(8'h0));
          cfg.clk_rst_vif.wait_clks(100);
        end

        disable fork;
      end
      begin
        read_rx_fifo();
      end
    join
  endtask : body

endclass : spi_host_spien_vseq


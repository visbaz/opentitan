// Copyright lowRISC contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

// passthrough_mode test vseq
// SPI_HOST HWIP Technical Specification Block Diagram
class spi_host_passthrough_mode_vseq extends spi_host_tx_rx_vseq;
  `uvm_object_utils(spi_host_passthrough_mode_vseq)
  `uvm_object_new

  bit en;

  virtual task pre_start();
    cfg.en_scb = 0;
    super.pre_start();
  endtask


  virtual task body();
    fork
      begin
      cfg.clk_rst_vif.wait_clks(5);
      en = 1'b1;
      for (int i = 0; i < (num_trans*num_runs); i++) begin
        @(posedge cfg.clk_rst_vif.clk);
        cfg.spi_passthrough_vif.passthrough_en <= 1'b1;
        cfg.clk_rst_vif.wait_clks($urandom_range(100, 200));
        `DV_CHECK_EQ(cfg.spi_passthrough_vif.cio_sd_i, cfg.spi_passthrough_vif.os)
        `DV_CHECK_EQ(cfg.spi_passthrough_vif.cio_sck_o, cfg.spi_passthrough_vif.sck)
        `DV_CHECK_EQ(cfg.spi_passthrough_vif.cio_sck_en_o, cfg.spi_passthrough_vif.sck_en)
        `DV_CHECK_EQ(cfg.spi_passthrough_vif.cio_csb_o, cfg.spi_passthrough_vif.csb)
        `DV_CHECK_EQ(cfg.spi_passthrough_vif.cio_csb_en_o, cfg.spi_passthrough_vif.csb_en)
        `DV_CHECK_EQ(cfg.spi_passthrough_vif.cio_sd_en_o, cfg.spi_passthrough_vif.s_en)
        `DV_CHECK_EQ(cfg.spi_passthrough_vif.is, cfg.spi_passthrough_vif.cio_sd_o)
        cfg.spi_passthrough_vif.passthrough_en <= 1'b0;
        cfg.clk_rst_vif.wait_clks($urandom_range(100, 200));
      end
      cfg.clk_rst_vif.wait_clks(5);
      en = 1'b0;
    end
    begin
      cfg.spi_passthrough_vif.sck_en <= 1'b0;
      cfg.spi_passthrough_vif.csb_en <= 1'b0;
      cfg.spi_passthrough_vif.s_en   <= 1'b0;
      cfg.spi_passthrough_vif.csb    <= 1'b1;
      cfg.spi_passthrough_vif.sck    <= 1'b0;
      cfg.spi_passthrough_vif.is     <= 0;
      cfg.spi_passthrough_vif.cio_sd_i <= 'hf;
      cfg.clk_rst_vif.wait_clks(5);
      while (en) begin
        @(posedge cfg.clk_rst_vif.clk);
        cfg.spi_passthrough_vif.sck_en <= $urandom_range(0, 1);
        cfg.spi_passthrough_vif.csb_en <= $urandom_range(0, 1);
        cfg.spi_passthrough_vif.s_en   <= $urandom_range(0, 1);
        cfg.spi_passthrough_vif.csb    <= $urandom_range(0, 1);
        cfg.spi_passthrough_vif.sck    <= $urandom_range(0, 1);
        cfg.spi_passthrough_vif.is     <= $urandom_range(100, 2000);
        cfg.spi_passthrough_vif.cio_sd_i <= $urandom_range(100, 2000);
      end
      cfg.clk_rst_vif.wait_clks(5);
    end
    join
  endtask : body
endclass : spi_host_passthrough_mode_vseq

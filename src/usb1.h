#ifndef USB1_H
#define USB1_H

#ifdef DEBUG_USB1
#define DBG_USB1
#else
#define DBG_USB1 while(0)
#endif

#define USB_FPGA_STATUS_READ_FLAG_BIT   (0x0400)
#define USB_FPGA_STATUS_WRITE_FLAG_BIT  (0x0200)
#define USB_FPGA_STATUS_CTRL_FLAG_BIT   (0x0100)

#define USB_FPGA_STATUS_ALL_FLAG_BIT    (USB_FPGA_STATUS_READ_FLAG_BIT|USB_FPGA_STATUS_WRITE_FLAG_BIT|USB_FPGA_STATUS_CTRL_FLAG_BIT)

#define USB_INT_STATUS_SET_CONNECTED    (0x0001)
#define USB_SNES_STATUS_SET_READ        (0x0002)
#define USB_SNES_STATUS_SET_WRITE       (0x0004)
#define USB_SNES_STATUS_SET_CTRL        (0x0008)
#define USB_INT_STATUS_CLEAR_CONNECTED  (0x0100)
#define USB_SNES_STATUS_CLEAR_READ      (0x0200)
#define USB_SNES_STATUS_CLEAR_WRITE     (0x0400)
#define USB_SNES_STATUS_CLEAR_CTRL      (0x0800)

#endif

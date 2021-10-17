/***************************************************************************

  wswan.c

  Driver file to handle emulation of the Bandai WonderSwan
  By:

  Anthony Kruize

  Based on the WStech documentation by Judge and Dox.

***************************************************************************/

#include "driver.h"
#include "vidhrdw/generic.h"
#include "includes/wswan.h"
#include "devices/cartslot.h"

static ADDRESS_MAP_START (wswan_readmem, ADDRESS_SPACE_PROGRAM, 8)
	AM_RANGE( 0x00000, 0x03fff) AM_READ( MRA8_RAM )		/* 16kb RAM + 16kb 4 colour tiles */
	AM_RANGE( 0x04000, 0x0ffff) AM_READ( MRA8_NOP )		/* Not used */
	AM_RANGE( 0x10000, 0x1ffff) AM_READ( MRA8_BANK1 )	/* SRAM bank */
	AM_RANGE( 0x20000, 0x2ffff) AM_READ( MRA8_BANK2 )	/* ROM bank 1 */
	AM_RANGE( 0x30000, 0x3ffff) AM_READ( MRA8_BANK3 )	/* ROM bank 2 */
	AM_RANGE( 0x40000, 0x4ffff) AM_READ( MRA8_BANK4 )	/* ROM bank 3 */
	AM_RANGE( 0x50000, 0x5ffff) AM_READ( MRA8_BANK5 )	/* ROM bank 4 */
	AM_RANGE( 0x60000, 0x6ffff) AM_READ( MRA8_BANK6 )	/* ROM bank 5 */
	AM_RANGE( 0x70000, 0x7ffff) AM_READ( MRA8_BANK7 )	/* ROM bank 6 */
	AM_RANGE( 0x80000, 0x8ffff) AM_READ( MRA8_BANK8 )	/* ROM bank 7 */
	AM_RANGE( 0x90000, 0x9ffff) AM_READ( MRA8_BANK9 )	/* ROM bank 8 */
	AM_RANGE( 0xA0000, 0xAffff) AM_READ( MRA8_BANK10 )	/* ROM bank 9 */
	AM_RANGE( 0xB0000, 0xBffff) AM_READ( MRA8_BANK11 )	/* ROM bank 10 */
	AM_RANGE( 0xC0000, 0xCffff) AM_READ( MRA8_BANK12 )	/* ROM bank 11 */
	AM_RANGE( 0xD0000, 0xDffff) AM_READ( MRA8_BANK13 )	/* ROM bank 12 */
	AM_RANGE( 0xE0000, 0xEffff) AM_READ( MRA8_BANK14 )	/* ROM bank 13 */
	AM_RANGE( 0xF0000, 0xFffff) AM_READ( MRA8_BANK15 )	/* ROM bank 14 */
ADDRESS_MAP_END

static ADDRESS_MAP_START (wswan_writemem, ADDRESS_SPACE_PROGRAM, 8)
	AM_RANGE( 0x00000, 0x03fff) AM_WRITE( MWA8_RAM )		/* 16kb RAM + 16kb 4 colour tiles */
	AM_RANGE( 0x04000, 0x0ffff) AM_WRITE( MWA8_NOP )		/* Not used */
	AM_RANGE( 0x10000, 0x1ffff) AM_WRITE( MWA8_BANK1 )	/* SRAM bank */
	AM_RANGE( 0x20000, 0x2ffff) AM_WRITE( MWA8_BANK2 )	/* ROM bank 1 */
	AM_RANGE( 0x30000, 0x3ffff) AM_WRITE( MWA8_BANK3 )	/* ROM bank 2 */
	AM_RANGE( 0x40000, 0x4ffff) AM_WRITE( MWA8_BANK4 )	/* ROM bank 3 */
	AM_RANGE( 0x50000, 0x5ffff) AM_WRITE( MWA8_BANK5 )	/* ROM bank 4 */
	AM_RANGE( 0x60000, 0x6ffff) AM_WRITE( MWA8_BANK6 )	/* ROM bank 5 */
	AM_RANGE( 0x70000, 0x7ffff) AM_WRITE( MWA8_BANK7 )	/* ROM bank 6 */
	AM_RANGE( 0x80000, 0x8ffff) AM_WRITE( MWA8_BANK8 )	/* ROM bank 7 */
	AM_RANGE( 0x90000, 0x9ffff) AM_WRITE( MWA8_BANK9 )	/* ROM bank 8 */
	AM_RANGE( 0xA0000, 0xAffff) AM_WRITE( MWA8_BANK10 )	/* ROM bank 9 */
	AM_RANGE( 0xB0000, 0xBffff) AM_WRITE( MWA8_BANK11 )	/* ROM bank 10 */
	AM_RANGE( 0xC0000, 0xCffff) AM_WRITE( MWA8_BANK12 )	/* ROM bank 11 */
	AM_RANGE( 0xD0000, 0xDffff) AM_WRITE( MWA8_BANK13 )	/* ROM bank 12 */
	AM_RANGE( 0xE0000, 0xEffff) AM_WRITE( MWA8_BANK14 )	/* ROM bank 13 */
	AM_RANGE( 0xF0000, 0xFffff) AM_WRITE( MWA8_BANK15 )	/* ROM bank 14 */
ADDRESS_MAP_END

static ADDRESS_MAP_START (wsc_readmem, ADDRESS_SPACE_PROGRAM, 8)
	AM_RANGE( 0x00000, 0x03fff) AM_READ( MRA8_RAM )		/* 16kb RAM + 16kb 4 colour tiles */
	AM_RANGE( 0x04000, 0x0ffff) AM_READ( MRA8_RAM )		/* 16 colour tiles + palettes */
	AM_RANGE( 0x10000, 0x1ffff) AM_READ( MRA8_BANK1 )	/* SRAM bank */
	AM_RANGE( 0x20000, 0x2ffff) AM_READ( MRA8_BANK2 )	/* ROM bank 1 */
	AM_RANGE( 0x30000, 0x3ffff) AM_READ( MRA8_BANK3 )	/* ROM bank 2 */
	AM_RANGE( 0x40000, 0x4ffff) AM_READ( MRA8_BANK4 )	/* ROM bank 3 */
	AM_RANGE( 0x50000, 0x5ffff) AM_READ( MRA8_BANK5 )	/* ROM bank 4 */
	AM_RANGE( 0x60000, 0x6ffff) AM_READ( MRA8_BANK6 )	/* ROM bank 5 */
	AM_RANGE( 0x70000, 0x7ffff) AM_READ( MRA8_BANK7 )	/* ROM bank 6 */
	AM_RANGE( 0x80000, 0x8ffff) AM_READ( MRA8_BANK8 )	/* ROM bank 7 */
	AM_RANGE( 0x90000, 0x9ffff) AM_READ( MRA8_BANK9 )	/* ROM bank 8 */
	AM_RANGE( 0xA0000, 0xAffff) AM_READ( MRA8_BANK10 )	/* ROM bank 9 */
	AM_RANGE( 0xB0000, 0xBffff) AM_READ( MRA8_BANK11 )	/* ROM bank 10 */
	AM_RANGE( 0xC0000, 0xCffff) AM_READ( MRA8_BANK12 )	/* ROM bank 11 */
	AM_RANGE( 0xD0000, 0xDffff) AM_READ( MRA8_BANK13 )	/* ROM bank 12 */
	AM_RANGE( 0xE0000, 0xEffff) AM_READ( MRA8_BANK14 )	/* ROM bank 13 */
	AM_RANGE( 0xF0000, 0xFffff) AM_READ( MRA8_BANK15 )	/* ROM bank 14 */
ADDRESS_MAP_END

static ADDRESS_MAP_START (wsc_writemem, ADDRESS_SPACE_PROGRAM, 8)
	AM_RANGE( 0x00000, 0x03fff) AM_WRITE( MWA8_RAM )		/* 16kb RAM + 16kb 4 colour tiles */
	AM_RANGE( 0x04000, 0x0ffff) AM_WRITE( MWA8_RAM )		/* 16 colour tiles + palettes */
	AM_RANGE( 0x10000, 0x1ffff) AM_WRITE( MWA8_BANK1 )	/* SRAM bank */
	AM_RANGE( 0x20000, 0x2ffff) AM_WRITE( MWA8_BANK2 )	/* ROM bank 1 */
	AM_RANGE( 0x30000, 0x3ffff) AM_WRITE( MWA8_BANK3 )	/* ROM bank 2 */
	AM_RANGE( 0x40000, 0x4ffff) AM_WRITE( MWA8_BANK4 )	/* ROM bank 3 */
	AM_RANGE( 0x50000, 0x5ffff) AM_WRITE( MWA8_BANK5 )	/* ROM bank 4 */
	AM_RANGE( 0x60000, 0x6ffff) AM_WRITE( MWA8_BANK6 )	/* ROM bank 5 */
	AM_RANGE( 0x70000, 0x7ffff) AM_WRITE( MWA8_BANK7 )	/* ROM bank 6 */
	AM_RANGE( 0x80000, 0x8ffff) AM_WRITE( MWA8_BANK8 )	/* ROM bank 7 */
	AM_RANGE( 0x90000, 0x9ffff) AM_WRITE( MWA8_BANK9 )	/* ROM bank 8 */
	AM_RANGE( 0xA0000, 0xAffff) AM_WRITE( MWA8_BANK10 )	/* ROM bank 9 */
	AM_RANGE( 0xB0000, 0xBffff) AM_WRITE( MWA8_BANK11 )	/* ROM bank 10 */
	AM_RANGE( 0xC0000, 0xCffff) AM_WRITE( MWA8_BANK12 )	/* ROM bank 11 */
	AM_RANGE( 0xD0000, 0xDffff) AM_WRITE( MWA8_BANK13 )	/* ROM bank 12 */
	AM_RANGE( 0xE0000, 0xEffff) AM_WRITE( MWA8_BANK14 )	/* ROM bank 13 */
	AM_RANGE( 0xF0000, 0xFffff) AM_WRITE( MWA8_BANK15 )	/* ROM bank 14 */
ADDRESS_MAP_END

static ADDRESS_MAP_START (wswan_readport, ADDRESS_SPACE_IO, 8)
	AM_RANGE( 0x00, 0xff) AM_READ( wswan_port_r )		/* I/O ports */
ADDRESS_MAP_END

static ADDRESS_MAP_START (wswan_writeport, ADDRESS_SPACE_IO, 8)
	AM_RANGE( 0x00, 0xff) AM_WRITE( wswan_port_w )		/* I/O ports */
ADDRESS_MAP_END

INPUT_PORTS_START( wswan )
	PORT_START /* IN 0 : cursors */
	PORT_BIT_NAME( 0x1, IP_ACTIVE_HIGH, IPT_JOYSTICK_UP,    "Up" )
	PORT_BIT_NAME( 0x4, IP_ACTIVE_HIGH, IPT_JOYSTICK_DOWN,  "Down" )
	PORT_BIT_NAME( 0x8, IP_ACTIVE_HIGH, IPT_JOYSTICK_LEFT,  "Left" )
	PORT_BIT_NAME( 0x2, IP_ACTIVE_HIGH, IPT_JOYSTICK_RIGHT, "Right" )
	PORT_START /* IN 1 : Buttons */
	PORT_BIT_NAME( 0x2, IP_ACTIVE_HIGH, IPT_START1,         "Start" )
	PORT_BIT_NAME( 0x4, IP_ACTIVE_HIGH, IPT_BUTTON1,        "Button A" )
	PORT_BIT_NAME( 0x8, IP_ACTIVE_HIGH, IPT_BUTTON2,        "Button B" )
INPUT_PORTS_END

static struct GfxDecodeInfo gfxdecodeinfo[] =
{ { -1 } /* end of array */ };

/* WonderSwan can display 16 shades of grey */
static PALETTE_INIT( wswan )
{
	int ii;
	for( ii = 0; ii < 8; ii++ )
	{
		UINT8 shade = ii * (256 / 8);
		palette_set_color( 7 - ii, shade, shade, shade );
	}
}

static struct CustomSound_interface wswan_sound_interface =
{ wswan_sh_start, 0, 0 };

static MACHINE_DRIVER_START( wswan )
	/* Basic machine hardware */
	/* FIXME: CPU should be a V30MZ not a V30! */
	MDRV_CPU_ADD_TAG("main", V30, 3072000)		/* 3.072 Mhz */
	MDRV_CPU_PROGRAM_MAP(wswan_readmem, wswan_writemem)
	MDRV_CPU_IO_MAP(wswan_readport, wswan_writeport)
	MDRV_CPU_VBLANK_INT(wswan_scanline_interrupt, 158/*159?*/)	/* 1 int each scanline */

	MDRV_FRAMES_PER_SECOND(60)
	MDRV_VBLANK_DURATION(0)
	MDRV_INTERLEAVE(1)

	MDRV_MACHINE_INIT( wswan )
	MDRV_MACHINE_STOP( wswan )

	MDRV_VIDEO_START( generic_bitmapped )
	MDRV_VIDEO_UPDATE( generic_bitmapped )

	MDRV_VIDEO_ATTRIBUTES(VIDEO_TYPE_RASTER)
	MDRV_SCREEN_SIZE(28*8, 18*8)
	MDRV_VISIBLE_AREA(0*8, 28*8-1, 0*8, 18*8-1)
	MDRV_GFXDECODE(gfxdecodeinfo)
	MDRV_PALETTE_LENGTH(8)
	MDRV_COLORTABLE_LENGTH(4*16)
	MDRV_PALETTE_INIT(wswan)

	/* sound hardware */
	MDRV_SOUND_ADD(CUSTOM, wswan_sound_interface)
MACHINE_DRIVER_END

static MACHINE_DRIVER_START( wscolor )
	MDRV_IMPORT_FROM(wswan)
	MDRV_CPU_MODIFY("main")
	MDRV_CPU_PROGRAM_MAP(wsc_readmem, wsc_writemem)
	MDRV_PALETTE_LENGTH(4096)
MACHINE_DRIVER_END

SYSTEM_CONFIG_START(wswan)
	CONFIG_DEVICE_CARTSLOT_REQ( 1, "ws\0wsc\0", NULL, NULL, device_load_wswan_cart, NULL, NULL, NULL)
SYSTEM_CONFIG_END

/***************************************************************************

  Game driver(s)

***************************************************************************/

ROM_START( wswan )
	ROM_REGION( 0x100000, REGION_CPU1, 0 )
ROM_END

ROM_START( wscolor )
	ROM_REGION( 0x100000, REGION_CPU1, 0 )
ROM_END

/*     YEAR  NAME     PARENT  COMPAT  MACHINE  INPUT  INIT  CONFIG  COMPANY   FULLNAME*/
CONSX( 1999, wswan,   0,      0,      wswan,   wswan, 0,    wswan,  "Bandai", "WonderSwan",       GAME_NOT_WORKING )
CONSX( 2000, wscolor, wswan,  0,      wscolor, wswan, 0,    wswan,  "Bandai", "WonderSwan Color", GAME_NOT_WORKING )

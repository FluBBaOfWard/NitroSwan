#ifndef _WSWAN_H_
#define _WSWAN_H_

#define WSWAN_TYPE_MONO 0
#define WSWAN_TYPE_COLOR 1
#define WSWAN_VIDMODE_4_MONO 0
#define WSWAN_VIDMODE_4_PALETTE 1
#define WSWAN_VIDMODE_16_LAYERED 2
#define WSWAN_VIDMODE_16_PACKED 3

/* Interrupt flags */
#define WSWAN_IFLAG_STX    0x1
#define WSWAN_IFLAG_KEY    0x2
#define WSWAN_IFLAG_RTC    0x4
#define WSWAN_IFLAG_SRX    0x8
#define WSWAN_IFLAG_LCMP   0x10
#define WSWAN_IFLAG_VBLTMR 0x20
#define WSWAN_IFLAG_VBL    0x40
#define WSWAN_IFLAG_HBLTMR 0x80
/* Interrupts */
#define WSWAN_INT_STX    0
#define WSWAN_INT_KEY    1
#define WSWAN_INT_RTC    2
#define WSWAN_INT_SRX    3
#define WSWAN_INT_LCMP   4
#define WSWAN_INT_VBLTMR 5
#define WSWAN_INT_VBL    6
#define WSWAN_INT_HBLTMR 7


struct VDP
{
	UINT8 layer_bg_enable;			/* Background layer on/off */
	UINT8 layer_fg_enable;			/* Foreground layer on/off */
	UINT8 sprites_enable;			/* Sprites on/off */
	UINT8 window_sprites_enable;	/* Sprite window on/off */
	UINT8 window_fg_mode;			/* 0:inside/outside, 1:??, 2:inside, 3:outside */
	UINT8 current_line;				/* Current scanline : 0-158 (159?) */
	UINT8 line_compare;				/* Line to trigger line interrupt on */
	UINT32 sprite_table_address;	/* Address of the sprite table */
	UINT8 sprite_first;				/* First sprite to draw */
	UINT8 sprite_last;				/* Last sprite to draw */
	UINT16 layer_bg_address;		/* Address of the background screen map */
	UINT16 layer_fg_address;		/* Address of the foreground screen map */
	UINT8 window_fg_left;			/* Left coordinate of foreground window */
	UINT8 window_fg_top;			/* Top coordinate of foreground window */
	UINT8 window_fg_right;			/* Right coordinate of foreground window */
	UINT8 window_fg_bottom;			/* Bottom coordinate of foreground window */
	UINT8 window_sprites_left;		/* Left coordinate of sprites window */
	UINT8 window_sprites_top;		/* Top coordinate of sprites window */
	UINT8 window_sprites_right;		/* Right coordinate of sprites window */
	UINT8 window_sprites_bottom;	/* Bottom coordinate of sprites window */
	UINT8 layer_bg_scroll_x;		/* Background layer X scroll */
	UINT8 layer_bg_scroll_y;		/* Background layer Y scroll */
	UINT8 layer_fg_scroll_x;		/* Foreground layer X scroll */
	UINT8 layer_fg_scroll_y;		/* Foreground layer Y scroll */
	UINT8 lcd_enable;				/* LCD on/off */
	UINT8 icons;					/* FIXME: What do we do with these? Maybe artwork? */
	UINT8 video_mode;				/* 0:4 col/tile mono, 1:4 col/tile color, 2:16 col/tile layered, 3:16 col/tile packed */
	UINT8 timer_hblank_enable;		/* Horizontal blank interrupt on/off */
	UINT8 timer_hblank_mode;		/* Horizontal blank timer mode */
	UINT16 timer_hblank_freq;		/* Horizontal blank timer frequency */
	UINT8 timer_vblank_enable;		/* Vertical blank interrupt on/off */
	UINT8 timer_vblank_mode;		/* Vertical blank timer mode */
	UINT16 timer_vblank_freq;		/* Vertical blank timer frequency */
};

extern struct VDP vdp;

extern MACHINE_INIT( wswan );
extern MACHINE_STOP( wswan );
extern READ_HANDLER( wswan_port_r );
extern WRITE_HANDLER( wswan_port_w );
extern DEVICE_LOAD(wswan_cart);
extern INTERRUPT_GEN(wswan_scanline_interrupt);

/* vidhrdw/wswan.c */
extern void wswan_refresh_scanline(void);

/* sndhrdw/wswan.c */
extern int wswan_sh_start(const struct MachineSound* driver);

#endif /* _WSWAN_H_ */

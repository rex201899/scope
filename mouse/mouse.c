/*
 * Userspace program that communicates with the vga_ball device driver
 * through ioctls
 *
 * Stephen A. Edwards
 * Columbia University
 */

#include <stdio.h>
#include "vga_ball.h"
#include <sys/ioctl.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <string.h>
#include <unistd.h>

#include <stdlib.h>
#include <arpa/inet.h>
#include "usbmouse.h"

/* References on libusb 1.0 and the USB HID/mouse protocol
 * https://nxmnpg.lemoda.net/3/libusb_interrupt_transfer
 * http://libusb.org
 * http://www.dreamincode.net/forums/topic/148707-introduction-to-using-libusb-10/
 * http://www.usb.org/developers/devclass_docs/HID1_11.pdf
 */

int vga_ball_fd;

// for mouse
struct libusb_device_handle *mouse;
uint8_t endpoint_address;

/* Read and print the background color 
void print_background_color() {
  vga_ball_arg_t vla;
  
  if (ioctl(vga_ball_fd, VGA_BALL_READ_BACKGROUND, &vla)) {
      perror("ioctl(VGA_BALL_READ_BACKGROUND) failed");
      return;
  }
  printf("%02x %02x %02x\n",
	 vla.background.red, vla.background.green, vla.background.blue);
}

/* Set the background color 
void set_background_color(const vga_ball_color_t *c,unsigned short xcoord, unsigned short ycoord)
{
  vga_ball_arg_t vla;
  vla.x = xcoord;
  vla.y = ycoord;
  vla.background = *c;
  if (ioctl(vga_ball_fd, VGA_BALL_WRITE_BACKGROUND, &vla)) {
      perror("ioctl(VGA_BALL_SET_BACKGROUND) failed");
      return;
  }
}*/
void print_coordinate_info() {
  vga_ball_arg_t vla;

	if (ioctl(vga_ball_fd, VGA_BALL_READ_COORD, &vla)) {
		perror("ioctl(VGA_BALl_READ_COORD) failed");
		return;
	}
	//printf("(%d, %d)", vla.x, vla.y);
  printf("\n");
}

//Write the coordinates to the display 
void write_coordinates(vga_ball_arg_t* c)
{
	vga_ball_arg_t vla;
	vla = *c;
	printf("HERE(%d, %d)", vla.x, vla.y);
	if (ioctl(vga_ball_fd, VGA_BALL_WRITE_COORD, &vla)) {
		perror("ioctl(VGA_BALL_WRITE_COORD) failed");
		return;
	}
}

int main()
{

  vga_ball_arg_t vla;
  //-----------------------MOUSE_START-------------------------
    // struct sockaddr_in serv_addr;
  int px = 320;
  int py = 240;
  int numx, numy;
  int modifierss = 0;
  struct usb_mouse_packet packet;
  int transferred;
  // char keystate[12];

  /* Open the mouse */
  if ( (mouse = openmouse(&endpoint_address)) == NULL ) {
    fprintf(stderr, "Did not find a mouse\n");
    exit(1);
  }
    

  for (;;) 
  {
    libusb_interrupt_transfer(mouse, endpoint_address,
            (unsigned char *) &packet, sizeof(packet),
            &transferred, 0);
    // printf("%d\n", flg1);

    if (transferred == sizeof(packet)) {
      if (packet.pos_x > 0x88) {
        numx = -(0xFF - packet.pos_x + 1);
      }
      else { numx = packet.pos_x;}

      if (packet.pos_y > 0x88) {
        numy = -(0xFF - packet.pos_y + 1);
      }
      else { numy = packet.pos_y;}

      if (px < 1) { px = 1;}
      else if (px > 0 && px < 640) { px = px + numx; }
      else if (px > 639) { px = 639;}
      else {px = 320;}

      if (py < 1) { py = 1;}
      else if (py > 0 && py < 480) { py = py + numy; }
      else if (py > 479) { py = 479;}
      else {py = 240;}

      modifierss = packet.modifiers;
      vla.x = px;
      vla.y = py;
      printf("position of x, y are: %d %d; left click is %d\n",px,py,modifierss);
      }
    }
  //-----------------------mouse_END------------------------
  
  int flag = 0;
  int flag2 =0;
  int a =0;
 // int i;
  static const char filename[] = "/dev/vga_ball";
  vla.x = px;
  vla.y = py;
  //static const vga_ball_color_t colors[] = {
   // { 0xff, 0x00, 0x00 }, /* Red */
   // { 0x00, 0xff, 0x00 }, /* Green */
  //  { 0x00, 0x00, 0xff }, /* Blue */
   // { 0xff, 0xff, 0x00 }, /* Yellow */
   // { 0x00, 0xff, 0xff }, /* Cyan */
  //  { 0xff, 0x00, 0xff }, /* Magenta */
  //  { 0x80, 0x80, 0x80 }, /* Gray */
   // { 0x00, 0x00, 0x00 }, /* Black */
    //{ 0xff, 0xff, 0xff }  /* White */
  //};

# define COLORS 9

  printf("VGA ball Userspace program started\n");

  if ( (vga_ball_fd = open(filename, O_RDWR)) == -1) {
    fprintf(stderr, "could not open %s\n", filename);
    return -1;
  }

  printf("initial state: ");
 // print_background_color();
  print_coordinate_info();
  write_coordinates(&vla);
    printf("initial state: ");
 // print_background_color();
  print_coordinate_info();

  while(1) {
   // set_background_color(&colors[i % COLORS ],600,200);
    //print_background_color();
	
		if (flag ==0){
		vla.x = vla.x + 60;
		}
		

		/*if (flag2==0){
		vla.y = vla.y+ 20;
		}
		else 
		{
		vla.y = vla.y -20;
		}*/

		
		if(vla.x > 1250)
		{
		vla.x =30;
		}
		
		/*
		if(vla.y > 465)
		{
		flag2 = 1;
		}
		if(vla.y <16)
		{
		flag2 = 0;
		}*/
	
		//vla.x= 180;
		vla.y= 180;

		//printf("XandY(%d, %d)", vla.x, vla.y);
    		print_coordinate_info();
    		write_coordinates(&vla);
		a =a+1;
		printf("a:%d",a);

    		usleep(400000);

		//vla.x= 120;
		vla.y= 120;

		//printf("XandY(%d, %d)", vla.x, vla.y);
    		print_coordinate_info();
    		write_coordinates(&vla);
		usleep(400000);
		a=a+1;
		printf("a:%d",a);

  }
  
  printf("VGA BALL Userspace program terminating\n");
  return 0;
}

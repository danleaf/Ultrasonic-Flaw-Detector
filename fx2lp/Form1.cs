using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.Text;
using System.Windows.Forms;
using CyUSB;

namespace fx2lp
{
    public partial class Form1 : Form
    {
        USBDeviceList usbDevices;
        CyUSBDevice MyDevice;
        CyUSBEndPoint inEndPoint;
        CyUSBEndPoint outEndPoint;
        List<CyUSBEndPoint> EndPointList = new List<CyUSBEndPoint>();

        bool b = false;

        public Form1()
        {
            InitializeComponent();

            usbDevices = new USBDeviceList(CyConst.DEVICES_CYUSB);
            USBDevice dev = usbDevices[0];

            if (dev != null)
            {
                MyDevice = (CyUSBDevice)dev;

                GetEndPoint(MyDevice.Tree);
            }

            foreach (CyUSBEndPoint ep in EndPointList)
            {
                if (ep.Address == 0x86)
                    inEndPoint = ep;
                if (ep.Address == 0x2)
                    outEndPoint = ep;
            }
        }

        private void GetEndPoint(TreeNode devTree)
        {
            foreach (TreeNode node in devTree.Nodes)
            {
                if (node.Nodes.Count > 0)
                    GetEndPoint(node);
                else
                {
                    CyUSBEndPoint ept = node.Tag as CyUSBEndPoint;

                    if (ept != null)
                        EndPointList.Add(ept);
                }
            }
        }

        private void Form1_Load(object sender, EventArgs e)
        {
        }

        private void button1_Click(object sender, EventArgs e)
        {
            if (inEndPoint != null)
            {
                int len = 512;
                byte[] data = new byte[512];

                bool ret = inEndPoint.XferData(ref data, ref len);
                if(!ret)
                {
                    label1.Text = "Failed!";
                }
                else
                {
                    label1.Text = "";
                    for(int i=0;i<10;i++)
                    {
                        label1.Text += data[i].ToString("X") + " ";
                    }
                    label1.Text += "...";
                }
            }
        }

        private void button2_Click(object sender, EventArgs e)
        {
            if (outEndPoint != null)
            {
                int len = 6;
                byte[] data = new byte[6];

                if (b)
                {
                    data[0] = 0x55;
                    data[1] = 0xaa;
                    data[2] = 0x55;
                    data[3] = 0xaa;
                    data[4] = 0x55;
                    data[5] = 0xaa;
                }
                else
                {
                    data[1] = 0x55;
                    data[0] = 0xaa;
                    data[3] = 0x55;
                    data[2] = 0xaa;
                    data[5] = 0x55;
                    data[4] = 0xaa;
                }
                b = !b;

                bool ret = outEndPoint.XferData(ref data, ref len);
                if (!ret)
                {
                    label1.Text = "Failed!";
                }
                else
                {
                    label1.Text = "";
                    for (int i = 0; i < 6; i++)
                    {
                        label1.Text += data[i].ToString("X") + " ";
                    }
                    label1.Text += "...";
                }
            }
        }
    }
}

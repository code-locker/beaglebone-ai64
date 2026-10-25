// SPDX-License-Identifier: GPL-2.0
/*
 * tmpl_drv — application kernel-part template: a misc device whose read
 * returns a greeting. scripts/new-app.sh renames "tmpl" to the app name.
 */
#include <linux/fs.h>
#include <linux/miscdevice.h>
#include <linux/module.h>

static const char msg[] = "hello from the tmpl kernel module\n";

static ssize_t tmpl_read(struct file *file, char __user *buf, size_t len,
			 loff_t *off)
{
	return simple_read_from_buffer(buf, len, off, msg, sizeof(msg) - 1);
}

static const struct file_operations tmpl_fops = {
	.owner = THIS_MODULE,
	.read  = tmpl_read,
};

static struct miscdevice tmpl_dev = {
	.minor = MISC_DYNAMIC_MINOR,
	.name  = "tmpl_drv",		/* -> /dev/tmpl_drv */
	.fops  = &tmpl_fops,
	.mode  = 0444,
};

module_misc_device(tmpl_dev);

MODULE_LICENSE("GPL");
MODULE_DESCRIPTION("BeagleBone AI-64 tmpl application driver");

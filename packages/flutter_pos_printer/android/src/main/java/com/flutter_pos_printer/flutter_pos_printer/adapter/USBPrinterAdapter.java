package com.flutter_pos_printer.flutter_pos_printer.adapter;

import android.app.PendingIntent;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.hardware.usb.UsbConstants;
import android.hardware.usb.UsbDevice;
import android.hardware.usb.UsbDeviceConnection;
import android.hardware.usb.UsbEndpoint;
import android.hardware.usb.UsbInterface;
import android.hardware.usb.UsbManager;
import android.util.Base64;
import android.util.Log;
import android.widget.Toast;

import java.nio.charset.Charset;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collections;
import java.util.List;
import java.util.Vector;

public class USBPrinterAdapter {
    private static USBPrinterAdapter mInstance;

    private String LOG_TAG = "ESC POS Printer";
    private Context mContext;
    private UsbManager mUSBManager;
    private PendingIntent mPermissionIndent;
    private UsbDevice mUsbDevice;
    private UsbDeviceConnection mUsbDeviceConnection;
    private UsbInterface mUsbInterface;
    private UsbEndpoint mEndPoint;
    private static final String ACTION_USB_PERMISSION = "com.flutter_pos_printer.USB_PERMISSION";

    private static Object printLock = new Object();

    private USBPrinterAdapter() {
    }

    public static USBPrinterAdapter getInstance() {
        if (mInstance == null) {
            mInstance = new USBPrinterAdapter();
        }
        return mInstance;
    }

    private final BroadcastReceiver mUsbDeviceReceiver = new BroadcastReceiver() {
        @Override
        public void onReceive(Context context, Intent intent) {
            String action = intent.getAction();
            if (ACTION_USB_PERMISSION.equals(action)) {
                synchronized (this) {
                    UsbDevice usbDevice = intent.getParcelableExtra(UsbManager.EXTRA_DEVICE);
                    if (intent.getBooleanExtra(UsbManager.EXTRA_PERMISSION_GRANTED, false)) {
                        Log.i(LOG_TAG, "Success get permission for device " + usbDevice.getDeviceId() + ", vendor_id: " + usbDevice.getVendorId() + " product_id: " + usbDevice.getProductId());
                        mUsbDevice = usbDevice;
                    } else {
                        Toast.makeText(context, "User refused to give USB device permission: " + usbDevice.getDeviceName(), Toast.LENGTH_LONG).show();
                    }
                }
            } else if (UsbManager.ACTION_USB_DEVICE_DETACHED.equals(action)) {
                if (mUsbDevice != null) {
                    Toast.makeText(context, "USB device disconnected", Toast.LENGTH_LONG).show();
                    closeConnection();
                }
            }
        }
    };

    public void init(Context reactContext) {
        this.mContext = reactContext;
        this.mUSBManager = (UsbManager) this.mContext.getSystemService(Context.USB_SERVICE);
        this.mPermissionIndent = PendingIntent.getBroadcast(mContext, 0, new Intent(ACTION_USB_PERMISSION), 0);
        IntentFilter filter = new IntentFilter(ACTION_USB_PERMISSION);
        filter.addAction(UsbManager.ACTION_USB_DEVICE_DETACHED);
        mContext.registerReceiver(mUsbDeviceReceiver, filter);
        Log.v(LOG_TAG, "ESC/POS Printer initialized");
    }

    public void closeConnection() {
        if (mUsbDeviceConnection != null) {
            mUsbDeviceConnection.releaseInterface(mUsbInterface);
            mUsbDeviceConnection.close();
            mUsbInterface = null;
            mEndPoint = null;
            mUsbDeviceConnection = null;
        }
    }

    public List<UsbDevice> getDeviceList() {
        if (mUSBManager == null) {
            Toast.makeText(mContext, "USB Manager is not initialized while trying to get devices list", Toast.LENGTH_LONG).show();
            return Collections.emptyList();
        }
        return new ArrayList(mUSBManager.getDeviceList().values());
    }

    public boolean selectDevice(Integer vendorId, Integer productId) {
        if (mUsbDevice == null || mUsbDevice.getVendorId() != vendorId || mUsbDevice.getProductId() != productId) {
            synchronized (printLock) {
                closeConnection();
                List<UsbDevice> usbDevices = getDeviceList();
                for (UsbDevice usbDevice : usbDevices) {
                    if ((usbDevice.getVendorId() == vendorId) && (usbDevice.getProductId() == productId)) {
                        Log.v(LOG_TAG, "Request for device: vendor_id: " + usbDevice.getVendorId() + ", product_id: " + usbDevice.getProductId());
                        closeConnection();
                        mUSBManager.requestPermission(usbDevice, mPermissionIndent);
                        return true;
                    }
                }
            }
            return false;
        }
        return true;
    }

    public boolean openConnection() {
        if (mUsbDevice == null) {
            Log.e(LOG_TAG, "USB device is not initialized");
            return false;
        }
        if (mUSBManager == null) {
            Log.e(LOG_TAG, "USB Manager is not initialized");
            return false;
        }

        if (mUsbDeviceConnection != null) {
            Log.i(LOG_TAG, "USB device already connected");
            return true;
        }

        UsbInterface usbInterface = mUsbDevice.getInterface(0);
        for (int i = 0; i < usbInterface.getEndpointCount(); i++) {
            final UsbEndpoint ep = usbInterface.getEndpoint(i);
            if (ep.getType() == UsbConstants.USB_ENDPOINT_XFER_BULK) {
                if (ep.getDirection() == UsbConstants.USB_DIR_OUT) {
                    UsbDeviceConnection usbDeviceConnection = mUSBManager.openDevice(mUsbDevice);
                    if (usbDeviceConnection == null) {
                        Log.e(LOG_TAG, "Failed to open USB Connection");
                        return false;
                    }
                    Toast.makeText(mContext, "Device connected", Toast.LENGTH_SHORT).show();
                    if (usbDeviceConnection.claimInterface(usbInterface, true)) {
                        mEndPoint = ep;
                        mUsbInterface = usbInterface;
                        mUsbDeviceConnection = usbDeviceConnection;
                        return true;
                    } else {
                        usbDeviceConnection.close();
                        Log.e(LOG_TAG, "Failed to retrieve usb connection");
                        return false;
                    }
                }
            }
        }
        return true;
    }

    public boolean printText(String text) {
        final String printData = text;
        Log.v(LOG_TAG, "Printing text");
        boolean isConnected = openConnection();
        if (isConnected) {
            Log.v(LOG_TAG, "Connected to device");
            new Thread(new Runnable() {
                @Override
                public void run() {
                    synchronized (printLock) {
                        byte[] bytes = printData.getBytes(Charset.forName("UTF-8"));
                        int b = mUsbDeviceConnection.bulkTransfer(mEndPoint, bytes, bytes.length, 100000);
                        Log.i(LOG_TAG, "Return code: " + b);
                    }
                }
            }).start();
            return true;
        } else {
            Log.v(LOG_TAG, "Failed to connect to device");
            return false;
        }
    }

    public boolean printRawData(String data) {
        final String rawData = data;
        Log.v(LOG_TAG, "Printing raw data: " + data);
        boolean isConnected = openConnection();
        if (isConnected) {
            Log.v(LOG_TAG, "Connected to device");
            new Thread(new Runnable() {
                @Override
                public void run() {
                    synchronized (printLock) {
                        byte[] bytes = Base64.decode(rawData, Base64.DEFAULT);
                        int b = mUsbDeviceConnection.bulkTransfer(mEndPoint, bytes, bytes.length, 100000);
                        Log.i(LOG_TAG, "Return code: " + b);
                    }
                }
            }).start();
            return true;
        } else {
            Log.v(LOG_TAG, "Failed to connected to device");
            return false;
        }
    }

    public boolean printBytes(ArrayList<Integer> bytes) {
        final ArrayList<Integer> bytesArray = bytes;
        Log.v(LOG_TAG, "Printing bytes");
        boolean isConnected = openConnection();
        if (isConnected) {
            final int chunkSize = 4096;
            Log.v(LOG_TAG, "Max Packet Size: " + chunkSize);
            Log.v(LOG_TAG, "Connected to device");
            new Thread(new Runnable() {
                @Override
                public void run() {
                    synchronized (printLock) {
                        Vector<Byte> vectorData = new Vector<>();
                        for (int i = 0; i < bytesArray.size(); ++i) {
                            Integer val = bytesArray.get(i);
                            vectorData.add(val.byteValue());
                        }
                        Object[] temp = vectorData.toArray();
                        byte[] buffer = new byte[temp.length];
                        for (int i = 0; i < temp.length; i++) {
                            buffer[i] = (byte) temp[i];
                        }

                        int b = 0;

                        if (buffer.length > chunkSize) {
                            int chunks = buffer.length / chunkSize;
                            if (buffer.length % chunkSize > 0) {
                                ++chunks;
                            }
                            for (int i = 0; i < chunks; ++i) {
                                boolean isLast = buffer.length - chunkSize < chunkSize;
                                int current = i * chunkSize;
                                int size =
                                        isLast ? (buffer.length - chunkSize) + current : chunkSize + i * chunkSize;
                                byte[] chunk = Arrays.copyOfRange(buffer, current, size);
                                b = mUsbDeviceConnection.bulkTransfer(mEndPoint, chunk, chunkSize, 100000);
                            }
                        } else {
                            b = mUsbDeviceConnection.bulkTransfer(mEndPoint, buffer, buffer.length, 100000);
                        }
                        Log.i(LOG_TAG, "Return code: " + b);
                    }
                }
            }).start();
            return true;
        } else {
            Log.v(LOG_TAG, "Failed to connected to device");
            return false;
        }
    }
}

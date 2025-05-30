import struct
import sys
from scapy.all import Ether, Dot3, Raw, Padding, sniff
import matplotlib.pyplot as plt

# --- Configuration ---
TARGET_MAC_ADDRESS = "00:00:5e:00:fa:ce"  # FPGA's MAC address
INTERFACE_NAME = "Ethernet"                # Network interface card name
PACKETS_TO_CAPTURE = 2                   # Number of packets to capture

sine_wave_samples = []
ENDIANNESS_FORMAT = '>h'
debug_packet_counter = 0 


def process_packet(packet):
    global sine_wave_samples, debug_packet_counter
    debug_packet_counter += 1

    payload_bytes = b''

    if packet.haslayer(Dot3):
        dot3_frame = packet[Dot3]
        if hasattr(dot3_frame.payload, 'load') and isinstance(dot3_frame.payload, (Padding, Raw)):
            payload_bytes = dot3_frame.payload.load
        elif isinstance(dot3_frame.payload, bytes):
            payload_bytes = dot3_frame.payload
        else:
            try:
                payload_bytes = bytes(dot3_frame.payload)
            except Exception:
                print(f"    DEBUG: ERROR converting dot3_frame.payload to bytes")
                return

        if not isinstance(payload_bytes, bytes):
            print(f"    DEBUG: WARNING: Extracted payload is not of type 'bytes'")
            return

    elif packet.haslayer(Ether):
        eth_frame = packet[Ether]
        try:
            payload_bytes = bytes(eth_frame.payload)
        except Exception:
            print(f"    DEBUG: ERROR converting eth_frame.payload (Ether) to bytes")
            return
    else:
        print("  DEBUG: Packet does NOT HAVE a recognized Dot3 or Ether layer by Scapy.")
        return

    samples_extracted_this_packet = 0
    for i in range(0, payload_len, 2):
        word_bytes = payload_bytes[i:i+2]
        try:
            sample = struct.unpack(ENDIANNESS_FORMAT, word_bytes)[0]
            sine_wave_samples.append(sample)
            samples_extracted_this_packet += 1
        except struct.error:
            print(f"    DEBUG: ERROR struct.unpack for bytes: {word_bytes.hex()}")
            pass  # Ignore malformed samples


def plot_data_and_exit():
    print("\nplot_data_and_exit function called.")
    print(f"Total original samples (from {PACKETS_TO_CAPTURE} packet(s)): {len(sine_wave_samples)}")

    if not sine_wave_samples:
        print("No samples collected to plot.")
        sys.exit(0)

    plt.figure(figsize=(12, 6))
    plt.plot(sine_wave_samples, label=f"Samples", color='blue')
    plt.title(f"Data from {PACKETS_TO_CAPTURE} Ethernet Packet(s)")
    plt.xlabel("Sample Index")
    plt.ylabel("Sample Value (signed 16-bit)")
    plt.legend()
    plt.grid(True)
    print("Displaying graph... Close the graph window to exit.")
    plt.show()

    print("Exiting script.")
    sys.exit(0)


if __name__ == "__main__":
    if TARGET_MAC_ADDRESS == "XX:XX:XX:XX:XX:XX" or len(TARGET_MAC_ADDRESS) != 17:
        print(f"ERROR: TARGET_MAC_ADDRESS ('{TARGET_MAC_ADDRESS}') does not seem correct!")
        sys.exit(1)
    if not INTERFACE_NAME:
        print(f"ERROR: INTERFACE_NAME is not set!")
        sys.exit(1)

    bpf_filter = f"ether src host {TARGET_MAC_ADDRESS}"

    print("IMPORTANT: Run this script with ADMINISTRATOR PRIVILEGES.")
    print(f"Starting sniffing on interface '{INTERFACE_NAME}'")
    print(f"Filter applied: '{bpf_filter}'")
    print(f"Exactly {PACKETS_TO_CAPTURE} packets matching the filter will be captured.")
    print("Ensure the FPGA is sending data...")

    try:
        sniff(iface=INTERFACE_NAME, filter=bpf_filter, prn=process_packet, store=0, count=PACKETS_TO_CAPTURE)
        print(f"\nSniffing complete. Processed {debug_packet_counter} packets that matched the filter.")
    except PermissionError:
        print("PERMISSION ERROR: Run the script as ADMINISTRATOR.")
        sys.exit(1)
    except RuntimeError as e:
        if "admin" in str(e).lower() or "permission" in str(e).lower():
            print(f"PERMISSION ERROR during sniffing: {e}")
        elif "no such device" in str(e).lower() or "failed to set filter" in str(e).lower():
            print(f"ERROR: Problem with interface '{INTERFACE_NAME}' or filter '{bpf_filter}': {e}")
        else:
            print(f"ERROR (RuntimeError) during sniffing attempt: {e}")
        sys.exit(1)
    except Exception as e:
        print(f"An unexpected error occurred during sniffing: {e}")
        sys.exit(1)

    plot_data_and_exit()
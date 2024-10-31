import socket
import pdfcovert


def client_program():
    host = socket.gethostname()  # as both code is running on same pc
    port = 7826  # socket server port number

    client_socket = socket.socket()  # instantiate
    client_socket.connect((host, port))  # connect to the server

    i = 1

    while True:

        hidden_data = input("Data to send -> ")

        send_pdf_name = input("Name of pdf to send -> ")


        pdfcovert.embed_data_in_pdf(send_pdf_name, "encrypted.pdf", hidden_data) # encrpyt message in pdf metadata

        pdf = open("encrypted.pdf", "rb") # send pdf data over TCP
        send_data = pdf.read(1024)
        while send_data:
            client_socket.send(send_data)
            send_data = pdf.read(1024)
        
        pdf.close()

        file = open('file_'+ str(i)+".pdf",'wb')

        receive_data = client_socket.recv(1024)  # receive response

        while receive_data: # keep receiving response until end of file
            file.write(receive_data)
            receive_data = client_socket.recv(1024)
            if b'%EOF' in receive_data:
                file.write(receive_data)
                file.close()
                break
        
        # extract and decrypt hidden message in pdf metadata
        extracted_data = pdfcovert.extract_data_from_pdf('file_'+ str(i)+".pdf")
        print(extracted_data)

        i += 1

    client_socket.close()  # close the connection


if __name__ == '__main__':
    client_program()
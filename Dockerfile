# Use Node.js LTS base image
FROM node:18

# Set working directory
WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm install

# Copy the rest of the source code
COPY . .

# Expose port (adjust if different)
EXPOSE 3000

# Start the application
CMD ["npm", "start"]

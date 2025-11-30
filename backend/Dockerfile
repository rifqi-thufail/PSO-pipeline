FROM node:18-alpine

WORKDIR /app

# Install system dependencies
RUN apk add --no-cache postgresql-client curl

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm ci --only=production

# Copy source code
COPY . .

# Create uploads directory
RUN mkdir -p uploads/materials

EXPOSE 5001

HEALTHCHECK --interval=30s --timeout=5s --start-period=60s --retries=3 \
  CMD curl -f http://localhost:5001/health || exit 1

CMD ["node", "server.js"]

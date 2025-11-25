FROM node:18-alpine

# Set working directory
WORKDIR /app

# Install AWS SDK dependencies
RUN apk add --no-cache postgresql-client curl

# Copy package files
COPY package*.json ./

# Install production dependencies only
RUN npm ci --only=production

# Copy application code
COPY . .

# Create uploads directory (fallback, will use S3 in production)
RUN mkdir -p uploads/materials

# Expose port
EXPOSE 5001

# Health check
HEALTHCHECK --interval=30s --timeout=5s --start-period=60s --retries=3 \
  CMD curl -f http://localhost:5001/api/auth/check || exit 1

# Start application
CMD ["node", "server.js"]

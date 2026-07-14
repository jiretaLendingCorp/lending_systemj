// supabase/functions/_shared/errors.ts
export class AppError extends Error {
  public readonly statusCode: number;
  public readonly code: string;
  public readonly details?: unknown;

  constructor(statusCode: number, code: string, message: string, details?: unknown) {
    super(message);
    this.statusCode = statusCode;
    this.code = code;
    this.details = details;
    Object.setPrototypeOf(this, AppError.prototype);
  }
}

function errorResponse(
  status: number,
  code: string,
  message: string,
  details?: unknown
): Response {
  const body = {
    error: code,
    message,
    ...(details !== undefined && { details }),
  };
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}

export function badRequest(message: string, details?: unknown): Response {
  return errorResponse(400, "BAD_REQUEST", message, details);
}

export function unauthorized(message = "Authentication required"): Response {
  return errorResponse(401, "UNAUTHORIZED", message);
}

export function forbidden(message = "Insufficient permissions"): Response {
  return errorResponse(403, "FORBIDDEN", message);
}

export function notFound(resource: string): Response {
  return errorResponse(404, "NOT_FOUND", `${resource} not found`);
}

export function conflict(message: string, details?: unknown): Response {
  return errorResponse(409, "CONFLICT", message, details);
}

export function unprocessable(message: string, details?: unknown): Response {
  return errorResponse(422, "UNPROCESSABLE_ENTITY", message, details);
}

export function serverError(message = "Internal server error"): Response {
  return errorResponse(500, "INTERNAL_SERVER_ERROR", message);
}

export function successResponse<T>(
  data: T,
  status = 200,
  corsHeaders?: Record<string, string>
): Response {
  return new Response(JSON.stringify({ data }), {
    status,
    headers: {
      "Content-Type": "application/json",
      ...(corsHeaders ?? {}),
    },
  });
}

export function paginatedResponse<T>(
  data: T[],
  total: number,
  page: number,
  pageSize: number,
  corsHeaders?: Record<string, string>
): Response {
  return new Response(
    JSON.stringify({
      data,
      pagination: {
        total,
        page,
        pageSize,
        totalPages: Math.ceil(total / pageSize),
      },
    }),
    {
      status: 200,
      headers: {
        "Content-Type": "application/json",
        ...(corsHeaders ?? {}),
      },
    }
  );
}

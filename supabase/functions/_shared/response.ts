import { withCors } from './cors.ts'
import { HttpError } from './auth.ts'

export function jsonOk(data: unknown, init?: ResponseInit): Response {
  return withCors(
    Response.json(
      { data },
      {
        status: 200,
        ...(init ?? {}),
      },
    ),
  )
}

export function jsonError(err: unknown): Response {
  if (err instanceof HttpError) {
    return withCors(Response.json({ error: err.message }, { status: err.status }))
  }
  const message = err instanceof Error ? err.message : 'Unknown error'
  return withCors(Response.json({ error: message }, { status: 500 }))
}


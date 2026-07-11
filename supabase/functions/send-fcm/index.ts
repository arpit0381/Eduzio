// Deno Edge Function: send-fcm
// @ts-ignore
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
// @ts-ignore
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

declare const Deno: any;

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const supabaseClient = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? ""
    );

    const { title, body, target, targetRole, batchId, organizationId, isGlobal, userId } = await req.json();

    if (!title || !body) {
      throw new Error("Missing required fields: title, body");
    }

    // 1. Fetch target FCM tokens from notification_tokens
    let query = supabaseClient
      .from("notification_tokens")
      .select("fcm_token");

    if (isGlobal !== true) {
      if (!organizationId) {
        throw new Error("Missing required field: organizationId for non-global target");
      }
      query = query.eq("institute_id", organizationId);
    }

    if (target === "role" && targetRole) {
      query = query.eq("role", targetRole);
    } else if (target === "batch" && batchId) {
      // Query tokens of students enrolled in the batch
      const { data: studentTokens, error: err1 } = await supabaseClient
        .from("batch_students")
        .select("student_id")
        .eq("batch_id", batchId);

      if (err1) throw err1;
      const studentIds = (studentTokens ?? []).map((s: any) => s.student_id);
      
      query = query.in("user_id", studentIds);
    } else if (target === "user" && userId) {
      query = query.eq("user_id", userId);
    }

    const { data: tokensData, error: tokenErr } = await query;
    if (tokenErr) throw tokenErr;

    const tokens = (tokensData ?? []).map((t: any) => t.fcm_token);
    if (tokens.length === 0) {
      return new Response(JSON.stringify({ success: true, message: "No target devices found" }), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
        status: 200,
      });
    }

    // 2. Fetch Firebase Admin credentials from env
    const serviceAccountVar = Deno.env.get("FIREBASE_SERVICE_ACCOUNT");
    if (!serviceAccountVar) {
      throw new Error("FIREBASE_SERVICE_ACCOUNT environment variable is not set");
    }
    const serviceAccount = JSON.parse(serviceAccountVar);

    // 3. Obtain OAuth2 token for Firebase HTTP v1 API
    const accessToken = await getAccessToken(serviceAccount);

    // 4. Send FCM multicast messages using Firebase API
    const projectId = serviceAccount.project_id;
    const sendPromises = tokens.map(async (token: string) => {
      const response = await fetch(
        `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`,
        {
          method: "POST",
          headers: {
            "Authorization": `Bearer ${accessToken}`,
            "Content-Type": "application/json",
          },
          body: JSON.stringify({
            message: {
              token: token,
              notification: { title, body },
              data: {
                title,
                body,
                click_action: "FLUTTER_NOTIFICATION_CLICK",
              },
            },
          }),
        }
      );
      return response.json();
    });

    const results = await Promise.all(sendPromises);

    return new Response(JSON.stringify({ success: true, results }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
      status: 200,
    });
  } catch (error: any) {
    return new Response(JSON.stringify({ error: error.message }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
      status: 400,
    });
  }
});

// Helper: Get Google OAuth2 Access Token using Deno runtime libraries
async function getAccessToken(serviceAccount: any): Promise<string> {
  const header = { alg: "RS256", typ: "JWT" };
  const now = Math.floor(Date.now() / 1000);
  const claim = {
    iss: serviceAccount.client_email,
    scope: "https://www.googleapis.com/auth/firebase.messaging",
    aud: "https://oauth2.googleapis.com/token",
    exp: now + 3600,
    iat: now,
  };

  const encodedHeader = btoa(JSON.stringify(header)).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
  const encodedClaim = btoa(JSON.stringify(claim)).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
  const signatureInput = `${encodedHeader}.${encodedClaim}`;

  // Sign JWT using private key
  const privateKey = serviceAccount.private_key.replace(/\\n/g, "\n");
  const keyBuffer = pemToArrayBuffer(privateKey);
  const cryptoKey = await crypto.subtle.importKey(
    "pkcs8",
    keyBuffer,
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"]
  );

  const signature = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5",
    cryptoKey,
    new TextEncoder().encode(signatureInput)
  );

  const encodedSignature = btoa(String.fromCharCode(...new Uint8Array(signature)))
    .replace(/\+/g, "-")
    .replace(/\//g, "_")
    .replace(/=+$/, "");

  const jwt = `${signatureInput}.${encodedSignature}`;

  // Request Access Token
  const res = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion: jwt,
    }),
  });

  const data = await res.json();
  if (data.error) {
    throw new Error(`Auth failed: ${data.error_description || data.error}`);
  }
  return data.access_token;
}

// Convert PEM format private key to ArrayBuffer
function pemToArrayBuffer(pem: string): ArrayBuffer {
  const b64 = pem
    .replace(/-----BEGIN PRIVATE KEY-----/, "")
    .replace(/-----END PRIVATE KEY-----/, "")
    .replace(/\s/g, "");
  const byteString = atob(b64);
  const bytes = new Uint8Array(byteString.length);
  for (let i = 0; i < byteString.length; i++) {
    bytes[i] = byteString.charCodeAt(i);
  }
  return bytes.buffer;
}

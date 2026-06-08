"""
FastAPI Application Entry Point

Main API for the AI Orchestration Layer
"""

from fastapi import FastAPI, HTTPException, status
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import List, Dict, Optional
import logging

from src.logger import get_logger
from src.orchestrator import get_orchestrator
from src.config import config

# Setup logger
logger = get_logger(__name__)

# Initialize FastAPI app
app = FastAPI(
    title="Viz-AI Orchestration Layer",
    description="AI model orchestration and routing engine",
    version="0.1.0",
)

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:3000", "http://localhost:3001"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Initialize orchestrator
orchestrator = get_orchestrator()


# ============================================
# Request/Response Models
# ============================================

class ApiKeyConfig(BaseModel):
    """User's API key configuration"""
    id: str
    service_name: str
    service_type: str
    model_name: Optional[str] = None
    is_active: bool = True


class UserPreferences(BaseModel):
    """User preferences for AI interactions"""
    preferred_provider: Optional[str] = None
    voice_preference: str = 'neutral'
    temperature: float = 0.7
    max_tokens: Optional[int] = None


class ProcessRequestPayload(BaseModel):
    """Main request payload for orchestrator"""
    user_id: str
    user_input: str
    api_keys: List[ApiKeyConfig]
    preferences: Optional[UserPreferences] = None
    conversation_context: Optional[Dict] = None


class OrchestrationResponse(BaseModel):
    """Response from orchestration"""
    success: bool
    response: Optional[Dict] = None
    error: Optional[str] = None
    intent: Optional[str] = None
    provider: Optional[str] = None
    model: Optional[str] = None
    confidence: Optional[float] = None


# ============================================
# API Endpoints
# ============================================

@app.get("/health")
async def health_check():
    """Health check endpoint"""
    return {
        "status": "OK",
        "service": "viz-ai-orchestration",
        "version": "0.1.0"
    }


@app.post("/orchestrate", response_model=OrchestrationResponse)
async def orchestrate(payload: ProcessRequestPayload):
    """
    Main orchestration endpoint
    
    Process user input through orchestration pipeline:
    1. Intent classification
    2. Model routing
    3. Execution (placeholder)
    
    Args:
        payload: Request payload with user input and configuration
        
    Returns:
        Orchestration result with routing and response
    """
    
    logger.info(f"Received orchestration request from user: {payload.user_id}")
    
    try:
        # Validate API keys
        if not orchestrator.validate_api_keys([k.dict() for k in payload.api_keys]):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="No active API keys configured"
            )
        
        # Process request through orchestrator
        result = await orchestrator.process_request(
            user_input=payload.user_input,
            user_id=payload.user_id,
            user_api_keys=[k.dict() for k in payload.api_keys],
            user_preferences=payload.preferences.dict() if payload.preferences else None,
            conversation_context=payload.conversation_context,
        )
        
        if result['success']:
            return OrchestrationResponse(
                success=True,
                response=result['response'],
                intent=result['intent'],
                provider=result['provider'],
                model=result['model'],
                confidence=result['confidence'],
            )
        else:
            return OrchestrationResponse(
                success=False,
                error=result.get('error', 'Unknown error'),
            )
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Orchestration error: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )


@app.post("/classify-intent")
async def classify_intent(text: str):
    """
    Classify user intent from text
    
    Args:
        text: User input text
        
    Returns:
        Intent classification result
    """
    
    try:
        classifier = orchestrator.classifier
        result = classifier.classify_with_details(text)
        
        return {
            "success": True,
            "intent": result['intent'],
            "confidence": result['confidence'],
            "service_type": result['service_type'],
        }
        
    except Exception as e:
        logger.error(f"Intent classification error: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )


@app.post("/route-request")
async def route_request(
    service_type: str,
    api_keys: List[ApiKeyConfig],
    preferred_provider: Optional[str] = None,
):
    """
    Route request to appropriate model
    
    Args:
        service_type: Type of service (chat, coding, research, image, voice)
        api_keys: User's API keys
        preferred_provider: Optional preferred provider
        
    Returns:
        Routing decision
    """
    
    try:
        router = orchestrator.router
        decision = router.route(
            service_type=service_type,
            user_api_keys=[k.dict() for k in api_keys],
            user_preference=preferred_provider,
            fallback_enabled=True,
        )
        
        return {
            "success": True,
            "routing_decision": decision.dict(),
        }
        
    except Exception as e:
        logger.error(f"Routing error: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )


@app.get("/service-types")
async def get_service_types():
    """Get available service types and supported providers"""
    return {
        "service_types": config.SERVICE_TYPES
    }


# ============================================
# Startup/Shutdown Events
# ============================================

@app.on_event("startup")
async def startup_event():
    """Initialize on startup"""
    logger.info("AI Orchestration Layer starting up")
    logger.info(f"Environment: {config.ENVIRONMENT}")


@app.on_event("shutdown")
async def shutdown_event():
    """Cleanup on shutdown"""
    logger.info("AI Orchestration Layer shutting down")


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)

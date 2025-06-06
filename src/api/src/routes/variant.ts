import { Variant } from '#generated/prisma/index.js'
import prisma from '#prisma.js'
import { Request, Response, Router } from 'express'

const router = Router()

router.get('/variant', async (_: Request, res: Response) => {
  const variants = await prisma.variant.findMany()

  if (variants.length === 0) {
    res.status(404).json({ message: 'No variants found' })
    return
  }

  res.status(200).json(variants)
})

router.get('/variant/:id', async (req: Request, res: Response) => {
  const variant = await prisma.variant.findUnique({
    where: {
      id: req.params.id
    }
  })

  if (!variant) {
    res.status(404).json({ message: 'Variant not found' })
    return
  }

  res.status(200).json(variant)
})

router.post('/variant', async (req: Request, res: Response) => {
  const { question_id, text } = req.body as Variant

  if (!question_id || !text) {
    res.status(400).json({ message: 'Missing required fields' })
    return
  }

  const variant = await prisma.variant.create({
    data: {
      question_id,
      text
    }
  })

  res.status(201).json(variant)
})

router.put('/variant/:id', async (req: Request, res: Response) => {
  const { question_id, text } = req.body as Variant

  const variant = await prisma.variant.update({
    data: {
      question_id,
      text
    },
    where: {
      id: req.params.id
    }
  })

  res.status(200).json(variant)
})

router.delete('/variant/:id', async (req: Request, res: Response) => {
  const variant = await prisma.variant.findUnique({
    where: {
      id: req.params.id
    }
  })

  if (!variant) {
    res.status(404).json({ message: 'Variant not found' })
    return
  }

  const deletedVariant = await prisma.variant.delete({
    where: {
      id: req.params.id
    }
  })

  res.status(200).json(deletedVariant)
})

export default router
